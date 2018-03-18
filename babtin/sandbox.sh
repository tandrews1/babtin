#!/usr/bin/env bash

#
# "Because A Bash Tester Is Needed"
#
# Taylor Hartley Andrews 
# MIT SDM / Cybersecurity at Sloan 
# 6.824 Distributed Systems
#
# 6.824 Go labs arena / sandbox file v1.0.0

# ==============================================================================
# Begin helper functions
# ==============================================================================

golab-src-dir () {
   cd $GO_TEST_SRC
}

golab-test-std() {
   local name="$1"
   golab-src-dir
   if [ ! -z $THA_GO_DEBUG ]; then
      tester-test-cmd "stats-$THA_GO_STATS-debug-$THA_GO_DEBUG-$name" "go test -run $name"
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
      tester-test-cmd "stats-$THA_GO_STATS-debug-$THA_GO_DEBUG-races-$DSE_RACE_TEST-$name" \
         "go test -race -run $name"
      return $?
   else
      tester-test-cmd "rel-racecheck-$DSE_RACE_TEST-$name" \
         "go test -race -run $name"
      return $?
   fi
}

golab-test-with-dice-races () {
   local name="$1"
   let "die = $RANDOM % 6 + 1"
   if [ $die -le $BABTIN_1ST_DICE ]; then
      export DSE_RACE_TEST=1
      golab-test-races $name
      return $?
   else 
      export DSE_RACE_TEST=0
      golab-test-std $name
      return $?
   fi
}

# =============================================================================
# Babtin test stubs (these are required and hooked into by test framework)
# =============================================================================

# 
# barrage-cd-repo --
#
# Let Barrage cd to the repository under test.
#
barrage-cd-repo () {
   cd $GO_TEST_SRC
}

#
# tester-get-bug-from-log --
#
# Given a failing log, you have the option to dig out a reasonable bug summary
# to use as an identifier for duplicates.
#
tester-get-bug-from-log () {
   local failing_logfile="$1"
   # Will replace non filename safe chars _ to condense the summary.
   local namesafe_regex="[^A-Za-z0-9_-]"

   # 
   # The following somewhat fragile hacky sequence is important for making
   # coherent 6.824 test system failures into reasonable bug summaries.
   #
   # -Join msg line since it is not on the same line with the keyword FAIL
   # -Remove runtime timing nums
   # -replace weird chars with underscores to make filename safe
   # -trim some weirdness from the output to shorten it and make more readable
   #
   # The output of this command is read by Babtin and used in conjunction with
   # its integrated failure searching, and will create a bug dir with a best
   # attempt combination with whatever is found between the two.
   #
   grep "FAIL RACE DETECTED" $failing_logfile &> /dev/null
   if [ $? == 0 ]; then
      echo "FAIL RACE DETECTED $GO_TEST_PKG"
      return 
   fi

   # Dig out the standard test framework failure.
   grep "FAIL.*" -A 1 -m 1 $failing_logfile |paste -s |sed -e "s/.*Test.*\: //" -e "s/[0-9]//g" |sed -e "s/$namesafe_regex/_/g" |sed -e "s/_raft__s//"
}

#
# tester-summary -- 
#
# Called when SIGINT (ctrl-c) is received and the framework pauses to show
# status.
#
tester-summary () {
   echo "THA_GO_DEBUG=$THA_GO_DEBUG"
   echo "GOPATH=$GOPATH"
   echo "RACE_FLAG_DICE_VAL=$BABTIN_1ST_DICE"
   echo "GO_TEST_PKG=$GO_TEST_PKG"
   echo "GO_TEST_SRC=$GO_TEST_SRC"
}

# 
# tester-begin --
#
# Babtin will execute the tester-begin global setup function once at the
# beginning before looping on tester-next-test.
#
tester-begin () {
   #
   # Required by 6.824 test system
   #
   if [ -z $GOPATH ]; then
      echo  "ERROR: GOPATH not set."
      return 1
   fi

   #
   # Optional value for Babtin to roll a dice, and if it is less than or equal
   # to this val, it will run the tests with the -race flag to look for races.
   #
   if [ -z $BABTIN_1ST_DICE ]; then 
      export BABTIN_1ST_DICE=0
   fi

   #
   # The name of the Go test package to run. 
   #
   # XXX NOTE XXX For some reason, Go will run, PASS, and return non-zero
   # when given non-existent package names. So make sure you spell the name
   # correctly or you will get your hopes up seeing a bunch of "passes"
   # where Babtin sees Go pass, but Go isn't actually running any real tests...
   #
   # A good workaround is to start the tests, inject a syntax error into the
   # system under test, and confirm it starts catching build errors. Then you
   # know it is running Go tests correctly.
   #
   if [ -z $GO_TEST_PKG ]; then
      echo "Pick a Go test name by exporting GO_TEST_PKG environment variable"
      echo "Such as: "
      echo "export GO_TEST_PKG=TestBasicAgree2B"
      echo "export GO_TEST_PKG=TestFailAgree2B"
      echo "export GO_TEST_PKG=2B"
      echo "export GO_TEST_PKG=2C"
      return 1
   fi


   if [ -z $GO_TEST_SRC ]; then
      echo "Pick a Go test name by exporting GO_TEST_SRC environment variable"
      echo "Such as: "
      echo "export GO_TEST_SRC=\$GOPATH/src/raft"
      echo "export GO_TEST_SRC=\$GOPATH/src/kvraft"
      return 1
   fi

   # All good to start testing.
   return 0
}

#
# tester-next-test --
#
# Babtin will execute the tester-next-test function repeatedly, attempting to
# auto-triaging the output of this function, with the help of the custom
# tester-get-bug-from-log function above, iff this function returns non-zero.
#
tester-next-test () {
   golab-test-with-dice-races "$GO_TEST_PKG"
}



#
# tester-post-eval --
#
#     By default, for passive judgement based on what Babtin
#     automatically detected, just return the incoming test exit code.
#
#     Post test evaluation based on the finish test's log file.
#     Echo findings right into the log file so bug-namer can find them.
#
#     Currently looks for races from Go's race checker.
#
# args:
#     $1: logfile (path)
#     $2: cmd exit code (integer)
#
# returns:
#     0 for total pass, non-zero for failure.
#
#
tester-post-eval () {
   local logfile="$1"
   local cmd_exit_code="$2"
   echo -n "CMDEXIT=$cmd_exit_code "

   grep "RACE" $logfile 
   if [ $? == 0 ]; then
      echo  "FAIL RACE DETECTED" >> $logfile
      return 1
   fi

   # Currently don't evaluate wall time
   #local real_time="`grep "babtintime:real" $logfile |sed -e s/babtintime:real\ //`"
   #echo  "WALL_TIME $real_time"

   #
   # @refactor
   # Dedup all this into a helper function.
   #

   local real_time="`grep "babtintime:real" $logfile |sed -e s/babtintime:real\ //`"
   local user_time="`grep "babtintime:user" $logfile |sed -e s/babtintime:user\ //`"
   local sys_time="`grep "babtintime:sys" $logfile |sed -e s/babtintime:sys\ //`"
   local user_time_max_sec=0
   local sys_time_max_sec=0
   echo -n "R:$real_time "
   echo -n "U:$user_time "
   echo -n "S:$sys_time "

   # 1B Time Checks
   if [ "$GO_TEST_PKG" == "2A" ]; then
      if [ ! -z $DSE_RACE_TEST ]; then
         user_time_max_sec=21
      else
         if [ ! -z $THA_GO_DEBUG ]; then
            user_time_max_sec=3
         else
            # Release
            user_time_max_sec=3
         fi
      fi
      if [ ! -z $DSE_RACE_TEST ]; then
         sys_time_max_sec=7
      else
         if [ ! -z $THA_GO_DEBUG ]; then
            sys_time_max_sec=8
         else
            # Release
            sys_time_max_sec=0.5
         fi
      fi
   fi

   # 2B User (CPU) time check
   if [ "$GO_TEST_PKG" == "2B" ]; then
      if [ ! -z $DSE_RACE_TEST ]; then
         user_time_max_sec=55
      else
         if [ ! -z $THA_GO_DEBUG ]; then
            user_time_max_sec=15
         else
            # Release
            user_time_max_sec=8
         fi
      fi
      if [ ! -z $DSE_RACE_TEST ]; then
         sys_time_max_sec=13
      else
         if [ ! -z $THA_GO_DEBUG ]; then
            sys_time_max_sec=5
         else
            # Release
            sys_time_max_sec=5
         fi
      fi
   fi

   if [ "$GO_TEST_PKG" == "2B" -o "$GO_TEST_PKG" == "2A" ]; then
      local one_if_gt="`echo $user_time_max_sec'>'$user_time | bc -l`"
      if [ "$one_if_gt" == "0" ]; then
         echo "FAIL $GO_TEST_PKG took too many user seconds" >> $logfile
         return 255
      fi

      local one_if_gt="`echo $sys_time_max_sec'>'$sys_time | bc -l`"
      if [ "$one_if_gt" == "0" ]; then
         echo "FAIL $GO_TEST_PKG took too many sys seconds" >> $logfile
         return 254
      fi
   fi

   return $cmd_exit_code
}
