#!/bin/bash

# Check if SABER_HOME is set
if [ -z "$SABER_HOME" ]; then
	echo "error: \$SABER_HOME is not set"
	exit 1
fi

# Source common functions
. "$SABER_HOME"/scripts/common.sh

# Source configuration parameters
. "$SABER_HOME"/scripts/saber.conf

USAGE="usage: theta-join.sh [ --batch-size ] [ --window-type-of-first-query ] [ --window-size-of-first-query ] [ --window-slide-of-first-query ] [ --input-attributes-of-first-query ] [...] [ --tuples-per-insert ]"

CLS="uk.ac.imperial.lsds.saber.experiments.microbenchmarks.scheduling.W2"

#
# Application-specific arguments
#
# Query task size (default is 1048576)
BATCH_SIZE=

# Window type of first stream: "row" for count-based or "range" for time-based windows 
# (default is "row")
WINDOW_TYPE1=

# Window size of first stream (default is 1024)
WINDOW_SIZE1=

# Window slide of first stream (default is 1024)
WINDOW_SLIDE1=

# Number of input attributes of first stream (default is 6)
INPUT_ATTRS1=

# Window type of second stream: "row" for count-based or "range" for time-based windows 
# (default is "row")
WINDOW_TYPE2=

# Window size of second stream (default is 1024)
WINDOW_SIZE2=

# Window slide of second stream (default is 1024)
WINDOW_SLIDE2=

# Number of tuples per insert (default is 128)
TUPLES_PER_INSERT=

# Parse application-specific arguments

while :
do
	case "$1" in
		--batch-size)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		BATCH_SIZE="$2"
		shift 2
		;;
		--window-type-of-first-query)
		saberOptionInSet "$1" "$2" "row" "range" || exit 1
		WINDOW_TYPE1="$2"
		shift 2
		;;
		--window-size-of-first-query)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		WINDOW_SIZE1="$2"
		shift 2
		;;
		--window-slide-of-first-query)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		WINDOW_SLIDE1="$2"
		shift 2
		;;
		--input-attributes-of-first-query)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		INPUT_ATTRS1="$2"
		shift 2
		;;
		--window-type-of-second-query)
		saberOptionInSet "$1" "$2" "row" "range" || exit 1
		WINDOW_TYPE2="$2"
		shift 2
		;;
		--window-size-of-second-query)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		WINDOW_SIZE2="$2"
		shift 2
		;;
		--window-slide-of-second-query)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		WINDOW_SLIDE2="$2"
		shift 2
		;;
		--tuples-per-insert)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		TUPLES_PER_INSERT="$2"
		shift 2
		;;
		-h | --help)
		echo $USAGE
		exit 0
		;;
		--*) 
		# Check if $1 is a system configuration argument	
		saberParseSysConfArg "$1" "$2"
		errorcode=$?
		if [ $errorcode -eq 0 ]; then
			shift 2
		elif [ $errorcode -eq 1 ]; then
			# $1 was a valid system configuration argument
			# but with a wrong value
			exit 1
		else
			echo "error: invalid option: $1" >&2
			exit 1
		fi
		;;
		*) # done, if string is empty
		if [ -n "$1" ]; then
			echo "error: invalid option: $1"
			exit 1
		fi
		break
		;;
	esac
done

#
# Configure app args
#
APPARGS=""

#
# Configure app args
#
APPARGS=""

[ -n "$BATCH_SIZE" ] && \
APPARGS="$APPARGS --batch-size $BATCH_SIZE"

[ -n "$WINDOW_TYPE1" ] && \
APPARGS="$APPARGS --window-type-of-first-stream $WINDOW_TYPE1"

[ -n "$WINDOW_SIZE1" ] && \
APPARGS="$APPARGS --window-size-of-first-stream $WINDOW_SIZE1"

[ -n "$WINDOW_SLIDE1" ] && \
APPARGS="$APPARGS --window-slide-of-first-stream $WINDOW_SLIDE1"

[ -n "$INPUT_ATTRS1" ] && \
APPARGS="$APPARGS --input-attributes-of-first-stream $INPUT_ATTRS1"

[ -n "$WINDOW_TYPE2" ] && \
APPARGS="$APPARGS --window-type-of-second-stream $WINDOW_TYPE2"

[ -n "$WINDOW_SIZE2" ] && \
APPARGS="$APPARGS --window-size-of-second-stream $WINDOW_SIZE2"

[ -n "$WINDOW_SLIDE2" ] && \
APPARGS="$APPARGS --window-slide-of-second-stream $WINDOW_SLIDE2"

[ -n "$TUPLES_PER_INSERT" ] && \
APPARGS="$APPARGS --tuples-per-insert $TUPLES_PER_INSERT"

#
# Configure system args
#
SYSARGS=""

saberSetSysArgs

#
# Execute application
errorcode=0
#
# if --experiment-duration is set, then we should run the experiment
# in the background.
#
if [ -z "$SABER_CONF_EXPERIMENTDURATION" ]; then
	
	"$SABER_HOME"/scripts/run.sh \
	--mode foreground \
	--class $CLS \
	-- $SYSARGS $APPARGS
else
	#
	# Find the experiments duration is seconds
	#
	interval="$SABER_CONF_PERFORMANCEMONITORINTERVAL"
	[ -z "$interval" ] && interval="1000" # in msec; the default interval
	
	# Duration is `interval` units
	units="$SABER_CONF_EXPERIMENTDURATION"
	
	# Duration in msecs
	msecs=`echo "$units * $interval" | bc`
	
	# Duration is seconds
	duration=`echo "scale=0; ${msecs} / 1000" | bc`
	
	# Round up
	remainder=`echo "${msecs} % 1000" | bc`
	if [ $remainder -gt 0 ]; then
		let duration++
	fi
	
	"$SABER_HOME"/scripts/run.sh --mode background --alias "two" --class $CLS --duration $duration -- $SYSARGS $APPARGS
	errorcode=$?
fi

exit $errorcode
