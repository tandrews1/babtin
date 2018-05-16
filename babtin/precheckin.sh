#!/usr/bin/env bash

babtin-dev () {
   cd ~/git/babtin/babtin
}

lab-dev-raft () {
   cd $GOPATH/src/raft; export GO_TEST_SRC=`pwd`;
}

lab-dev-test () {
   cd $GOPATH/src/raft; time go test -run $GO_TEST_PKG 2>&1 |tee /tmp/rfoutput
}

lab-dev-kv () {
   cd $GOPATH/src/kvraft; export GO_TEST_SRC=`pwd`
}

lab-dev-kvtest () {
   cd $GOPATH/src/kvraft; $time go test -run $GO_TEST_PKG 2>&1 |tee /tmp/kvoutput
}

run_test () {
   local env_cmd="$1"
   local test_pkg="$2"
   local test_str="$3"
   $env_cmd
   babtin-dev 
   echo "$test_pkg $test_str"
   GO_TEST_PKG=$test_pkg ./barrage.sh $test_str
   if [ $? != 0 ]; then
      exit 1
   else
      sleep 10
   fi
}

main () {
   export BARRAGE_FORKBOMB_WAIVER=1
   run_test "lab-dev-raft" "2A" "20 1"
   run_test "lab-dev-raft" "2B" "20 15"
   run_test "lab-dev-raft" "2C" "32 2"
   run_test "lab-dev-kv"   "3A" "32 1"
}

main $*
