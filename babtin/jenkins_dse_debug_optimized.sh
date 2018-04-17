#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


debug-barrage () {
   barrage-debug
   $SCRIPT_DIR/barrage.sh $1 $2
}

release-barrage () {
   barrage-release
   $SCRIPT_DIR/barrage.sh $1 $2
}
main () {
   local db_width=$1
   local db_depth=$2
   local rel_width=$3
   local rel_depth=$4
  
   export BARRAGE_FORKBOMB_WAIVER=1 
   if [ "$BARRAGE_RELEASE_ONLY" == "1" ]; then
      echo "DEBUG SKIPPED... checking RELEASE"
      release-barrage $rel_width $rel_depth
      rel_exit=$?
      if [ $rel_exit != 0 ]; then
         echo "***** RELEASE FAILED -- REGRESSION ALERT! *****"
      else 
         echo "RELEASE STABLE!"
      fi
      exit $rel_exit
   else
      debug-barrage $db_width $db_depth
      db_exit=$?
      if [ $db_exit != 0 ]; then
         echo "DEBUG FAILED... checking RELEASE"
         release-barrage $rel_width $rel_depth
         rel_exit=$?
         if [ $rel_exit != 0 ]; then
            echo "***** RELEASE FAILED -- REGRESSION ALERT! *****"
            exit $rel_exit
         else 
            echo "RELEASE STABLE! LOOKS LIKE DEBUG ISSUE!"
         fi
         exit $db_exit
      else
         echo "DEBUG PASS! SKIPPING RELEASE!"
      fi
   fi
}

. $SCRIPT_DIR/lib.sh
. $SCRIPT_DIR/sandbox.sh
main $*
