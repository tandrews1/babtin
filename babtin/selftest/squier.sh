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
            echo "ASSERT: ASSERT reason $((RANDOM % 10))"
         elif [ $failtype = 1 ]; then
            echo "Assert: Assert reason $((RANDOM % 10))"
         elif [ $failtype = 2 ]; then
            echo "assert: assert reason $((RANDOM % 10))"
         elif [ $failtype = 3 ]; then
            echo "FAIL: FAIL reason $((RANDOM % 10))"
         elif [ $failtype = 4 ]; then
            echo "Fail: Fail reason $((RANDOM % 10))"
         elif [ $failtype = 5 ]; then
            echo "fail: fail reason $((RANDOM % 10))"
         elif [ $failtype = 6 ]; then
            echo "ERROR: ERROR reason $((RANDOM % 10))"
         elif [ $failtype = 7 ]; then
            echo "Error: error reason $((RANDOM % 10))"
         elif [ $failtype = 8 ]; then
            echo "error: error reason $((RANDOM % 10))"
         elif [ $failtype = 9 ]; then
            echo "EXCEPTION: EXCEPTION reason $((RANDOM % 10))"
         elif [ $failtype = 10 ]; then
            echo "Exception: Exception reason $((RANDOM % 10))"
         elif [ $failtype == 11 ]; then
            echo "exception: exception reason $((RANDOM % 10))"
         elif [ $failtype = 12 ]; then
            echo "PANIC: Panic reason $((RANDOM % 10))"
         elif [ $failtype = 13 ]; then
            echo "Panic: Panic reason $((RANDOM % 10))"
         elif [ $failtype = 14 ]; then
            echo "panic: panic reason $((RANDOM % 10))"
         fi
         exit 1
      else
         echo "I pass!"
         exit 0
      fi
}
main
