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
   if [ $width -gt 8 ]; then
      echo "FORKBOMB RISK... Ctrl-C to cancel!"
      read
   fi
   mkdir -p $outdir
   echo ""
   i=0
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
   fi
}
main $*
