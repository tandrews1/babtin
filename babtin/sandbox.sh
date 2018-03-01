#!/usr/bin/env bash

#
# "Because A Bash Tester Is Needed"
#
# Taylor Hartley Andrews 
# MIT SDM / Cybersecurity at Sloan 
# 6.824 Distributed Systems
#

# Begin Sandbox helper code ====================================================

golab-src-dir () {
   cd $GOPATH && cd src/raft
}

golab-test-std() {
   local name="$1"
   golab-src-dir
   if [ ! -z $THA_GO_DEBUG ]; then
      tester-test-cmd "debug-$THA_GO_DEBUG-$name" "go test -run $name"
      return $?
   else
      tester-test-cmd "release-$name" "go test -run $name"
      return $?
   fi
}

golab-test-races() {
   local name="$1"
   golab-src-dir
   if [ ! -z $THA_GO_DEBUG ]; then
      tester-test-cmd "debug-$THA_GO_DEBUG-$name-race_$BABTIN_FIRST_DICE" \
         "go test -run $name"
      return $?
   else
      tester-test-cmd "release-$name-race_$BABTIN_FIRST_DICE" \
         "go test -run $name"
      return $?
   fi
}

golab-test-with-dice-races () {
   local name="$1" 
   let "die = $RANDOM % 6 + 1"
   if [ $die -le $BABTIN_FIRST_DICE ]; then
      golab-test-races $name
      return $?
   else 
      golab-test-std $name
      return $?
   fi
}

# =============================================================================
# Babtin test stubs (these are required and hooked into by test framework)
# =============================================================================

#
# tester-summary -- 
#
# Called when SIGINT (ctrl-c) is received.
#
tester-summary () {
   echo "GOPATH=$GOPATH"
   echo "RACE_DICE=$BABTIN_FIRST_DICE"
}

# 
# tester-begin --
#
# Babtin will execute the tester-begin function once at the beginning before
# looping on tester-next-test.
#
tester-begin () {
   if [ -z $GOPATH ]; then
      io-error "GOPATH not set."
      exit 1
   fi
   if [ -z $BABTIN_FIRST_DICE ]; then 
      io-error "BABTIN_FIRST_DICE not set."
      exit 1
   fi
}

#
# tester-next-test --
#
# Babtin will execute the tester-next-test function repeatedly,
# attempting to auto-triaging the output of this function,
# iff this function returns non-zero.
#
tester-next-test () {
   golab-test-with-dice-races "2A"
}
