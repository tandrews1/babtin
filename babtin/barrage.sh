#!/usr/bin/env bash

#
# Taylor H. Andrews bash 3rd party validation validation tool
# 6.824 Lab 1 - Map Reduce
# Friday Feb 16th 2018
#
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main () {
   local width=$1
   local depth=$2
   local outdir="$SCRIPT_DIR/tracker/barrage/barrage.$$"
   local log="$outdir/$i.log"
   assert-not-empty "$width" "$FUNCNAME" "$LINENO" "arg1 width"
   assert-not-empty "$width" "$FUNCNAME" "$LINENO" "arg2 depth"
   if [ $width -gt 8  ]; then
      if [ -z $BABTIN_FORKBOMB_WAIVER ]; then
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
   while [ $i -lt $width ]
   do
      echo "$i STARTING"
      $SCRIPT_DIR/babtin.sh --iters $depth 2>&1 |tee $outdir/$i.log &
      sleep 1
      i=$((i+1))
   done
   wait
   cd $outdir
   grep "FAIL" ./*
   if [ $? == 1 ]; then
      echo "$width X $depth $GO_TEST_PKG - ALL PASS"
      rm -r $outdir
   else
      mv $outdir $SCRIPT_DIR/tracker/fails
   fi
   local total_sec=$SECONDS
   time-seconds-to-human $total_sec
}

# Run!
. $SCRIPT_DIR/lib.sh
main $*
