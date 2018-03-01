#!/usr/bin/env bash

#
# Taylor H. Andrews bash 3rd party validation validation tool
# 6.824 Lab 1 - Map Reduce
# Friday Feb 16th 2018
#

# 6.824 aliases
lab2a-root () {
   cd $GOPATH
}
lab2a-raft-src() {
   lab2a-root && cd src/raft
}
lab2a-test() {
   logfile=/tmp/dev-lab2a-test.$$
   lab2a-raft-src && go test -run 2A |tee $logfile
   if [ ${PIPESTATUS[0]} != 0 ]; then
      exit 1
   else 
      rm $logfile
   fi
}
lab2a-test-races() {
   logfile=/tmp/dev-lab2a-race-check.$$
   lab2a-raft-src && go test -race -run 2A > $logfile
   if [ $? != 0 ]; then
      exit 1
   else
      rm $logfile
   fi
}
lab2a-test-thorough() {
   lab2a-test
   if [ $? != 0 ]; then
      return 1
   fi
   die=0
   let "die = $RANDOM % 6 + 1"
   if [ $die -gt $TEST_DIE_VAL ]; then
      echo "Die was $die; DECIDED TO CHECK FOR RACES... one moment..."
      lab2a-test-races
      if [ $? != 0 ]; then
         return 1
      fi
   else
      echo "Die was $die; skipping race check..."
   fi
}

fail () {
   name=$1
   num=$2
   msg="$3"
   io-error "T$num $name FAIL :( $msg"
   exit 1
}

pass () {
   name=$1
   num=$2
   msg="$3"
   echo "T$num $name PASS :) $msg"
}

test1passes=0

# Test 1, all of them...
test1 () {
   lab2a-test-thorough
   if [ $? == 0 ]; then
      test1passes=$((test1passes+1))
      pass lab2a-full 1 "$test1passes TOTAL PASSES!"
   else
      fail lab2a-full 1 "$test1passes TOTAL PASSES but then FAILURE!"
      exit 1
   fi
}

main () {
   echo "BEGINNING THOROUGH TESTS - LAB1_SRC_DIR=$LAB1_SRC_DIR"
   while :
   do
      test1
      echo "$test1passes consecutive passes (with $TEST_DIE_VAL/6 race checker)"
      echo "3 seconds until next iteration!"
      sleep 3
   done
}

# Use MBS for testing...
source $MBS_ROOT_DIR/core/mbs.sh > /dev/null

if [ -z $GOPATH ]; then
   io-error "GOPATH not set."
   exit 1
fi
if [ -z $TEST_DIE_VAL ]; then 
   io-error "TEST_DIE_VAL not set."
   exit 1
fi

# Set up for Lab
LAB1_SRC_DIR=$GOPATH/src/raft

# Run all tests! (Set THA_GO_DEBUG > 0 to activate debug mode)
main
