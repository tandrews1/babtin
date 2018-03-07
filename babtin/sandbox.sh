#!/usr/bin/env bash

#
# "Because A Bash Tester Is Needed"
#
# Taylor Hartley Andrews 
# MIT SDM / Cybersecurity at Sloan 
# 6.824 Distributed Systems
#

# ==============================================================================
# Begin Sandbox helper functions
# ==============================================================================

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
      tester-test-cmd "debug-$THA_GO_DEBUG-$name-race_$BABTIN_1ST_DICE" \
         "go test -run $name"
      return $?
   else
      tester-test-cmd "release-$name-race_$BABTIN_1ST_DICE" \
         "go test -run $name"
      return $?
   fi
}

golab-test-with-dice-races () {
   local name="$1" 
   let "die = $RANDOM % 6 + 1"
   if [ $die -le $BABTIN_1ST_DICE ]; then
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
# tester-get-bug-from-log --
#
# Given a failing log, you have the option to dig out a reasonable bug summary
# to use as an identifier for duplicates.
#
tester-get-bug-from-log () {
   local failing_logfile="$1"
  
   return 
   # Set up for 6.824 Go lab tester FAIL output with error right on next line

   # Replace nonsafe chars in summary string with _
   #local namesafe_regex="[^A-Za-z0-9._-]"
   #grep "FAIL.*" -A 1 -m 1 $failing_logfile |paste -s |sed -e "s/.*Test.*\: //" |sed -e "s/$namesafe_regex/_/g"
}

#
# tester-summary -- 
#
# Called when SIGINT (ctrl-c) is received and the framework pauses to show
# status.
#
tester-summary () {
   echo "GOPATH=$GOPATH"
   echo "RACE_FLAG_DICE_VAL=$BABTIN_1ST_DICE"
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
   if [ -z $BABTIN_1ST_DICE ]; then 
      io-error "BABTIN_1ST_DICE not set."
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
   golab-test-with-dice-races "TestBackup2B"
}
