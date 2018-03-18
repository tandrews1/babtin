#!/usr/bin/env bash

#
# Taylor H. Andrews bash 3rd party validation validation tool
# 6.824 Lab 1 - Map Reduce
# Friday Feb 16th 2018
#
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BABTIN_KILL_SWITCH=/tmp/BABTIN_DIE

main () {
   local width=$1
   local depth=$2
   assert-not-empty "$FUNCNAME" "$LINENO" "$width" "arg1 width"
   assert-not-empty "$FUNCNAME" "$LINENO" "$depth" "arg2 depth"
   pushd "`pwd`" > /dev/null
   barrage-cd-repo
   local last_git_commit="`git log |head -1 |sed s/commit\ //`"
   local git_branch="`git branch |grep \* |sed s/\*\ // |sed s/[^a-zA-Z0-9]/_/g`"
   assert-not-empty "$FUNCNAME" "$LINENO" "$last_git_commit" 
   assert-not-empty "$FUNCNAME" "$LINENO" "$git_branch"
   popd > /dev/null
   local outdir="$SCRIPT_DIR/tracker/running/barrage/$last_git_commit-$git_branch-$GO_TEST_PKG-$width-$depth.$$"
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
   export BABTIN_FAIL_DIR=$outdir
   if [ -f $BABTIN_KILL_SWITCH ]; then
      rm $BABTIN_KILL_SWITCH
   fi
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
. $SCRIPT_DIR/sandbox.sh
main $*
