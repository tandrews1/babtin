#!/usr/bin/env bash

#
# Taylor H. Andrews bash 3rd party validation validation tool
# 6.824 Lab 1 - Map Reduce
# Friday Feb 16th 2018
#
VERSION=1.0.0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BABTIN_KILL_SWITCH=/tmp/BABTIN_DIE

main () {
   local width=$1
   local depth=$2
   local tag=$3
   assert-not-empty "$FUNCNAME" "$LINENO" "$width" "arg1 width"
   assert-not-empty "$FUNCNAME" "$LINENO" "$depth" "arg2 depth"
   local barrage_name="`sandbox-get-name`-$width-X-$depth-barrage.$tag"
   assert-not-empty "$FUNCNAME" "$LINENO" "$barrage_name" "sandbox-get-name returned nothing"
   local outdir="$SCRIPT_DIR/tracker/running/barrage/$barrage_name.$$"
   local log="$outdir/$i.log"
   assert-not-empty "$width" "$FUNCNAME" "$LINENO" "arg1 width"
   assert-not-empty "$width" "$FUNCNAME" "$LINENO" "arg2 depth"
   if [ $width -gt 8  ]; then
      if [ -z $BARRAGE_FORKBOMB_WAIVER ]; then
         echo "HOST: `hostname`"
         echo "`ifconfig`"
         echo "WARNING: FORKBOMB RISK :D :D :D !!!!!!"
         echo "Ctrl-C to cancel!"
         read
      else
         echo "YOU SIGNED THE FORKBOMB WAIVER!"
      fi
   fi
   mkdir -p $outdir
   echo ""
   i=0
   export SECONDS=`pwd`
   export BABTIN_FAIL_DIR=$outdir
   if [ -f $BABTIN_KILL_SWITCH ]; then
      rm $BABTIN_KILL_SWITCH
   fi
   if [ -z $BARRAGE_START_DELAY ]; then
      export BARRAGE_START_DELAY=0.5
   fi
   if [ $width -gt 1 ]; then
      # parallel Babtins means it will have to compact output to just PASS/FAIL
      export BABTIN_BARRAGE=1
   fi
   while [ $i -lt $width ]
   do
      echo "$i STARTING"
      $SCRIPT_DIR/babtin.sh --iters $depth 2>&1 |tee $outdir/$i.log &
      sleep $BARRAGE_START_DELAY
      i=$((i+1))
   done
   wait
   cd $outdir
   unset BABTIN_BARRAGE
   if [ -f $BABTIN_KILL_SWITCH ]; then
      mkdir $SCRIPT_DIR/tracker/killed
      mv $outdir $SCRIPT_DIR/tracker/killed
   else
      grep -r "FAIL" ./*
      if [ $? == 1 ]; then
         do-graphic
         echo "$barrage_name - BARRAGE TESTING FULL PASS"
         rm -r $outdir
         local total_sec=$SECONDS
         time-seconds-to-human $total_sec
      else
         mv $outdir $SCRIPT_DIR/tracker/fails
         cd $SCRIPT_DIR/tracker/fails/$barrage_name.$$
         tree .
         echo $SCRIPT_DIR/tracker/fails/$barrage_name.$$
         local total_sec=$SECONDS
         time-seconds-to-human $total_sec
         exit 1
      fi
   fi
}

# Run!
. $SCRIPT_DIR/lib.sh
. $SCRIPT_DIR/sandbox.sh
main $*
