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
   if [ "$BARRAGE_RELEASE_ONLY" == "true" ]; then
      echo "DEBUG SKIPPED... checking RELEASE"
      release-barrage $rel_width $rel_depth
      rel_exit=$?
      if [ $rel_exit != 0 ]; then
         echo "***** RELEASE ONLY FAILED -- REGRESSION ALERT! *****"
      else 
         echo "RELEASE ONLY - STABLE!"
      fi
      exit $rel_exit
   else
      debug-barrage $db_width $db_depth
      db_exit=$?
      if [ $db_exit != 0 ]; then
         if "$BARRAGE_DEBUG_ONLY" == "false"]; then
            echo "DEBUG FAILED... auto-checking RELEASE"
            release-barrage $rel_width $rel_depth
            rel_exit=$?
            if [ $rel_exit != 0 ]; then
               echo "***** RELEASE FAILED -- REGRESSION ALERT! *****"
               exit $rel_exit
            else 
               echo "RELEASE STABLE! LOOKS LIKE DEBUG ISSUE!"
            fi
         else
            echo "***** DEBUG FAILED -- DID NOT TEST RELEASE! *****"
         fi
         exit $db_exit
      fi
      echo "DEBUG PASS! BARRAGE_DEBUG_ONLY=$BARRAGE_DEBUG_ONLY"
   fi
}

. $SCRIPT_DIR/lib.sh
. $SCRIPT_DIR/sandbox.sh
main $*
