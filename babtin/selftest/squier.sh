#!/usr/bin/env bash

# Test the tester.
main () {
      echo "Squier starting..."
      let "snooze = $RANDOM % 2"
      sleep $snooze
      let "shallfail = $RANDOM % 2"
      if [ $shallfail == 1 ]; then
         let "failtype = $RANDOM % 11"
         if [ $failtype = 0 ]; then
            echo "ASSERT: reason ASSERT alpha one"
         elif [ $failtype = 1 ]; then
            echo "Assert: reason Assert beta two"
         elif [ $failtype = 2 ]; then
            echo "assert: reason assert gamma three"
         elif [ $failtype = 3 ]; then
            echo "FAIL: reason FAIL alpha one"
         elif [ $failtype = 4 ]; then
            echo "Fail: reason Fail beta two"
         elif [ $failtype = 5 ]; then
            echo "fail: reason fail gamma three"
         elif [ $failtype = 6 ]; then
            echo "ERROR: reason ERROR alpha one"
         elif [ $failtype = 7 ]; then
            echo "Error: reason error beta two"
         elif [ $failtype = 8 ]; then
            echo "error: reason error gamma three"
         elif [ $failtype = 9 ]; then
            echo "EXCEPTION: reason EXCEPTION alpha one"
         elif [ $failtype = 10 ]; then
            echo "Exception: reason Exception beta two"
         elif [ $failtype == 11 ]; then
            echo "exception: reason exception gamma three"
         elif [ $failtype = 12 ]; then
            echo "PANIC: reason Panic alpha one"
         elif [ $failtype = 13 ]; then
            echo "Panic: reason Panic beta two"
         elif [ $failtype = 14 ]; then
            echo "panic: reason panic gamma three"
         fi
         exit 1
      else
         echo "I pass!"
         exit 0
      fi
}
main
