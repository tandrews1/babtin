#!/usr/bin/env bash

# Test the tester.
main () {
      echo "Squier starting..."
      let "snooze = $RANDOM % 3"
      sleep $snooze
      let "shallfail = $RANDOM % 2"
      if [ $shallfail == 1 ]; then
         let "failtype = $RANDOM % 3"
         if [ $failtype = 0 ]; then
            echo "ASSERT: assert reason $((RANDOM % 10))"
         elif [ $failtype = 1 ]; then
            echo "assert: assert reason $((RANDOM % 10))"
         elif [ $failtype = 2 ]; then
            echo "FAIL: fail reason $((RANDOM % 10))"
         elif [ $failtype = 3 ]; then
            echo "Fail: fail reason $((RANDOM % 10))"
         elif [ $failtype = 4 ]; then
            echo "fail: fail reason $((RANDOM % 10))"
         elif [ $failtype = 5 ]; then
            echo "ERROR: fail reason $((RANDOM % 10))"
         elif [ $failtype = 6 ]; then
            echo "Error: error reason $((RANDOM % 10))"
         else
            echo "error: error reason $((RANDOM % 10))"
         fi
         exit 1
      else
         echo "I pass!"
         exit 0
      fi
}
main
