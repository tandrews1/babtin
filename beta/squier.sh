#!/usr/bin/env bash


main () {
      echo "Squier starting..."
      let "snooze = $RANDOM % 3"
      sleep $snooze
      let "shallfail = $RANDOM % 2"
      if [ $shallfail == 1 ]; then
         let "failtype = $RANDOM % 3"
         if [ $failtype = 0 ]; then
            echo "ASSERT: $RANDOM_$RANDOM_$RANDOM"
         elif [ $failtype = 1 ]; then
            echo "assert: $RANDOM_$RANDOM_$RANDOM"
         elif [ $failtype = 2 ]; then
            echo "FAIL: $RANDOM_$RANDOM_$RANDOM"
         elif [ $failtype = 3 ]; then
            echo "Fail: $RANDOM_$RANDOM_$RANDOM"
         elif [ $failtype = 4 ]; then
            echo "fail: $RANDOM_$RANDOM_$RANDOM"
         elif [ $failtype = 5 ]; then
            echo "ERROR: $RANDOM_$RANDOM_$RANDOM"
         elif [ $failtype = 6 ]; then
            echo "Error: $RANDOM_$RANDOM_$RANDOM"
         elif [ $failtype = 7 ]; then
            echo "error: $RANDOM_$RANDOM_$RANDOM"
         fi
         exit 1
      else
         echo "I pass!"
         exit 0
      fi
}

main
