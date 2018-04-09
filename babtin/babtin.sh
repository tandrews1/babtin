#!/usr/bin/env bash

#
# "Because A Bash Tester Is Needed"
#
# Taylor Hartley Andrews 
# MIT SDM & Cybersecurity at Sloan 
# 6.824 Distributed Systems
#

VERSION=0.9.7.2
# Current directory of this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Files for syncing state to disk for eventual sharing between processes
WORKING_DIR=/tmp/babtin.$$
WORKING_TOTAL_PASS_FILE=/tmp/babtin.$$/status/total_pass
WORKING_TOTAL_FAIL_FILE=/tmp/babtin.$$/status/total_fail
WORKING_DICE_1_FILE=/tmp/babtin.$$/control/first_dice
WORKING_SIGINT_FILE=/tmp/babtin.$$/control/sigint
RUNNING_DIR=$SCRIPT_DIR/tracker/running/pid.$$/
SELFTEST=0

# In iterative mode, the number of iterations left.
let ITERATIONS=0

#
# get-test-log --
#
#      Produces a file path in the tracker's running directory where we can dump
#      the output of the current running test instance.
#
get-test-log () {
   local name=$1
   assert-not-empty "$FUNCNAME" "$LINENO" "$name" \
      "no name given"
   # For now, just use the test name with a random number appended
   local file_name="$name"
   assert-not-empty "$FUNCNAME" "$LINENO" "$file_name" \
      "file name empty"
   echo $RUNNING_DIR/$file_name.$RANDOM
}

do-graphic () {
   echo "                              _A_ "
   echo "                             / | \ "
   echo "                            |.-=-.| "
   echo "                            )\_|_/( "
   echo "                         .=='\   /'==. "
   echo "                       .'\   (':')   /'. "
   echo "                     _/_ |_.-' : '-._|__\_ "
   echo "                    <___>'\    :   / '<___> "
   echo "                    /  /   >=======<  /  / "
   echo "                  _/ .'   /  ,-:-.  \/=,' "
   echo "                 / _/    |__/v^v^v\__) \ "
   echo "                 \\(\\)     |V^V^V^V^V|\_/ "
   echo "                  (\\\\     \\'---|---'/ "
   echo "                    \\\\     \\-._|_,-/ "
   echo "     adapted from    \\\\     |__|__| "
   echo "    art by hjw        \\\\   <___X___> "
   echo "                       \\\\   \\..|../ "
   echo "                        \\\\   \\ | / "
   echo "                         \\\\  /V|V\ "
   echo "                          \\\\/  |  \ "
   echo "                           '--' '--' "
}

do-title () {
   echo ""
   echo "`io-color-start green`B.a.b.t.i.n. v$VERSION "
   if [ -z $ITERATIONS ]; then
      do-graphic
   fi
   echo "`io-color-stop green`"
   echo "Ctrl-C to pause for babtin cmd prompt"
   echo ""
   dump-env
}

dump-debug-env () {
   echo "BABTIN_TEST_PASS         =$BABTIN_TEST_PASS"
   echo "BABTIN_TEST_FAIL         =$BABTIN_TEST_FAIL"
   echo "BABTIN_1ST_DICE          =$BABTIN_1ST_DICE"
   echo "SIGINT_SKIP              =$SIGINT_SKIP"
}

dump-env () {
   echo "Babtin ---------------------------------------"
   echo "ITERATIONS               =$ITERATIONS"
   echo "SELFTEST                 =$SELFTEST"
   echo "WORKING_DIR              =$WORKING_DIR"
   echo "BABTIN_1ST_DICE    roll <=$BABTIN_1ST_DICE/6"
   echo "Sandbox --------------------------------------"
   echo "TODO"
   echo "Tester Summary -------------------------------"
   tester-summary
   if [ ! -z $BABTIN_DEBUG ]; then
      echo "Debug   --------------------------------------"
      dump-debug-env
   fi
}

# Sync state to disk from env.
# TODO: in progress. no watchdog timer for catching timeouts implemented yet.
#       workaround is noticing test has not moved in some time, killing tester
#       and looking at the output in the tracker's running directory.
do-env-export () {
   if [ -z $ITERATIONS ]; then
      #TODO wait on .lck file
      #TODO acquire .lck file
      local passes_file="$WORKING_TOTAL_PASS_FILE"
      local fails_file="$WORKING_TOTAL_FAIL_FILE"
      local die_1_file="$WORKING_DICE_1_FILE"
      local sigint_file="$WORKING_SIGINT_FILE"
      assert-file "$FUNCNAME" "$LINENO" "$passes_file" "pass file not found"
      assert-file "$FUNCNAME" "$LINENO" "$fails_file" "fail file not found"
      assert-file "$FUNCNAME" "$LINENO" "$die_1_file" "fail file not found"
      assert-file "$FUNCNAME" "$LINENO" "$sigint_file" "sigint file not found"
      assert-not-empty "$FUNCNAME" "$LINENO" "$BABTIN_TEST_PASS" "passes empty"
      assert-not-empty "$FUNCNAME" "$LINENO" "$BABTIN_TEST_FAIL" "fails empty"
      assert-not-empty "$FUNCNAME" "$LINENO" "$BABTIN_1ST_DICE" "die empty"
      assert-not-empty "$FUNCNAME" "$LINENO" "$SIGINT_SKIP" "sigint empty"
      #TODO release .lck file
      echo $BABTIN_TEST_PASS > $passes_file   && \
         echo $BABTIN_TEST_FAIL > $fails_file && \
         echo $BABTIN_1ST_DICE > $die_1_file     && \
         echo $SIGINT_SKIP > $sigint_file 
      assert-zero "$FUNCNAME" "$LINENO" "$?" "save failed"
   fi
}

# Sync state from disk into env.
do-env-import () {
   if [ -z $ITERATIONS ]; then
      #TODO wait on a .lck file
      #TODO acquire a .lck file
      local passes_file="$WORKING_TOTAL_PASS_FILE"
      local fails_file="$WORKING_TOTAL_FAIL_FILE"
      local die_1_file="$WORKING_DICE_1_FILE"
      local sigint_file="$WORKING_SIGINT_FILE"
      assert-file "$FUNCNAME" "$LINENO" "$passes_file" "pass file not found"
      assert-file "$FUNCNAME" "$LINENO" "$fails_file" "fail file not found"
      assert-file "$FUNCNAME" "$LINENO" "$die_1_file" "die 1 file not found"
      assert-file "$FUNCNAME" "$LINENO" "$sigint_file" "sigint file not found"
      local passes="`cat $passes_file`"
      local fails="`cat $fails_file`"
      local first_dice="`cat $die_1_file`"
      local sigint_status="`cat $sigint_file`"
      #TODO release .lck file
      assert-integer "$FUNCNAME" "$LINENO" "$passes" "passes not int"
      assert-integer "$FUNCNAME" "$LINENO" "$fails" "fails not int"
      assert-integer "$FUNCNAME" "$LINENO" "$first_dice" "die 1 not int"
      export BABTIN_TEST_PASS=$passes   && \
         export BABTIN_TEST_FAIL=$fails && \
         export BABTIN_1ST_DICE=$first_dice && \
         export SIGINT_SKIP=$sigint_status
      assert-zero "$FUNCNAME" "$LINENO" "$?" "import failed"
   fi
}

do-final-cleanup () {
   echo "Cleaning up..."
   rm -r $RUNNING_DIR 
   rm -r $WORKING_DIR 
}

do-exit () {
   local code=$1
   echo ""
   do-final-cleanup
   echo "Exiting..."
   exit $code
}

do-reset-tester-stats () {
   do-env-import
   export BABTIN_TEST_PASS=0
   export BABTIN_TEST_FAIL=0
   export SECONDS=0
   do-env-export
}

handle-sigint () {
   do-env-import   
   do-summary
   trap handle-sigint SIGINT
   local cmd=""
   echo ""
   echo -n "e to exit, enter to continue> "
   local pause_seconds=$SECONDS
   read cmd
   if [ "$cmd" == "e" -o "$cmd" == "E" -o "$cmd" == "exit" ]; then
      do-exit 255
   elif [ "$cmd" == "reset" ]; then
      do-reset-tester-stats
      echo "Reset tester stats!"
   else
      # Make the pass streak pick up where it left off if they resume.
      export SECONDS=$pause_seconds
   fi
   export SIGINT_SKIP=1
   do-env-export
   echo "Resuming testing..."
}

do-summary () {
   local time="`time-seconds-to-human $SECONDS`"
   do-env-import
   if [ "`which tree`" != "" ]; then
      echo ""
      tree -ChDdt  $BABTIN_FAIL_DIR
   fi
   #ls -ltrh $BABTIN_FAIL_DIR
   echo -en "`io-color-start green`$BABTIN_TEST_PASS pass streak ($time)`io-color-stop green` | "
   if [ ! -z $BABTIN_TEST_FAIL ]; then
      echo -en "`io-color-start red`"
      echo -en "$BABTIN_TEST_FAIL fail(s)"
      echo -e "`io-color-stop red`"
   else 
      echo "No failures yet!"
   fi
   dump-env
}

#
# TODO:
# Necessary to sync stuff to disk in preparation for a watchdog timer thread
# that can shoot down long running tests with a timeout before other things
# go horribly wrong.
#
init-working-dir () {
   mkdir -p $WORKING_DIR/status
   echo 0 > $WORKING_TOTAL_PASS_FILE
   echo 0 > $WORKING_TOTAL_FAIL_FILE
   mkdir -p /tmp/babtin.$$/control
   if [ -z $BABTIN_1ST_DICE ]; then
      echo 0 > $WORKING_DICE_1_FILE
      export BABTIN_1ST_DICE=0
   else
      echo $BABTIN_1ST_DICE > $WORKING_DICE_1_FILE
   fi
   echo 0 > $WORKING_SIGINT_FILE
}

#
# Searches common strings like ASSERT, error, fail, exception, and panic.
# and tries to smash out a single_underscored_summary as a rough summary of
# the error, potentially for a file or directory name.
#
# TODO remove debug statements
#
bug-summary-from-log () {
   local logfile="$1"
   assert-file "$FUNCNAME" "$LINENO" "$logfile" "arg1 log"
   local user_supplied_parse=""
   local user_supplied_parse_safe=""
   if [ $SELFTEST == 0 ]; then
      user_supplied_parse="`tester-get-bug-from-log $logfile`"
      user_supplied_parse_safe=""
      if [ "$user_supplied_parse" != "" ]; then
         user_supplied_parse_safe="`basename $user_supplied_parse`"
      fi 
   fi
   # 
   # else: Sandbox function may not have echoed a bug summary, so look for
   # common failure strings.
   #
   # They didn't specify any bug name from the sandbox function, so do our best
   # to dig one out through looking for assert, fail, error, exception, and 
   # panic strings.
   #
   local search_regex="panic[^a-zA-Z]\|assert[^a-zA-Z]\|exception[^a-zA-Z]\|error[^a-zA-Z]\|fail[^a-zA-Z]"
   #echo "searching"
   #echo "grep -m 1 \"$search_regex\" -i $logfile"
   local search_result="`grep -m 1 \"$search_regex\" -i $logfile`"
   local first_try=""
   if [ "$search_result" != "" ]; then
      local error_regex="^.*assert[^a-zA-Z]\|^.*fail[^a-zA-Z]\|^.*error[^a-zA-Z]\|^.*exception[^a-zA-Z]\|^.*panic[^a-zA-Z]"
      #echo "echo \"$search_result\" |sed -e \"s/$error_regex//i\""
      local error_grab="`echo \"$search_result\" \
         |sed -e \"s/$error_regex//i\"`"
      local smash_regex="[^A-Za-z_-]"
      #echo "smashin"
      #echo "echo \"$error_grab\" |sed -e s/\"$smash_regex\"/_/g"
      first_try="`echo \"$error_grab\" |sed -e s/\"$smash_regex\"/_/g`"
   fi
   # If the user was able to dig out something, append that before our
   # default parsing.
   if [  "$user_supplied_parse_safe" == "" ]; then
      # Final trim... get rid of tons of underscores...
      echo "$first_try" |sed -e "s/__//g"
   else
      # Final trim... get rid of tons of underscores...
      printf "%s_%s" "$user_supplied_parse_safe" "$first_try" |sed -e "s/__//g"
   fi
}

test-fail () {
   local logfile="$1"
   assert-file "$FUNCNAME" "$LINENO" "$logfile" "arg1 log"
   echo -e "`io-color-start red`FAIL `io-color-stop red`"
   # Specifically leave out of quotes to truncate any spaces.
   # Bug summary from log needs more testing.
   local summary="`bug-summary-from-log $logfile`"
   # Leave a basename for security so logs can't somehow create
   # other paths all over the place.
   local summary_safe="$summary"
   if [ "$summary" != "" ]; then 
      local summary_safe="`basename $summary`"
   fi
   if [ "$summary" != "" ]; then
      if [ ! -d "$BABTIN_FAIL_DIR/$summary" ]; then
         echo -e "`io-color-start red`NEW BUG: $summary`io-color-stop red`"
         mkdir -p "$BABTIN_FAIL_DIR/$summary"
      else 
         echo "It's another $summary"
      fi
      mv $logfile "$BABTIN_FAIL_DIR/$summary"
   else
      echo "Could not auto-triage failure :("
      mkdir -p "$BABTIN_FAIL_DIR/unknown"
      mv $logfile "$BABTIN_FAIL_DIR/unknown"
   fi
   do-env-import
   export BABTIN_TEST_FAIL=1
   # Start the passing streak over...
   export BABTIN_TEST_PASS=0
   export SECONDS=0
   do-env-export
}

test-pass () {
   local logfile="$1"
   assert-not-empty "$FUNCNAME" "$LINENO" "$logfile" "log file empty"
   echo "`io-color-start green`PASS `io-color-stop green`"
   do-env-import
   export BABTIN_TEST_PASS=$((BABTIN_TEST_PASS+1))
   do-env-export
   #TODO there will be an option to preserve passing logs eventually
   # if [ ! -z PRESERVE_PASSING_LOGS ]; then ...
   rm $logfile
}

tester-test-cmd () {
   local name="$1"
   local cmd="$2"
   assert-not-empty "$FUNCNAME" "$LINENO" "$name" "arg1 empty"
   assert-not-empty "$FUNCNAME" "$LINENO" "$cmd" "arg2 empty"
   local logfile="`get-test-log $name`"
   local time_fmt_str="babtintime:real %E\nbabtintime:user %U\nbabtintime:sys %S"
   echo "$cmd" >> $logfile
   (/usr/bin/time -f "$time_fmt_str" $cmd) &> $logfile
   cmd_exit=$?
   printf "(%16s) %s: " "`time-seconds-to-human $SECONDS`" "$name"
   if [ -z $ITERATIONS ]; then
      # If we handled a sigint and returned, then just abort the current test...
      if [ $cmd_exit != 0 ]; then
         do-env-import
         assert-integer "$FUNCNAME" "$LINENO" "$SIGINT_SKIP" \
            "SIGINT skip not synced right"
         if [ $SIGINT_SKIP == 1 ]; then
            trap handle-sigint SIGINT
            export SIGINT_SKIP=0
            do-env-export
            echo "Starting a new test..."
            return 130
         fi
         #test-fail "$logfile"
      fi
   fi
      
   # Although it looks like it passed, we need to let the sandbox function have
   # the final call since we can't trust the exit code fully.
   tester-post-eval "$logfile" "$cmd_exit"
   sandbox_eval_code=$?
   if [ $sandbox_eval_code != 0 ]; then
      test-fail "$logfile"
   else
      test-pass "$logfile"
   fi
}

test-squire () {
   tester-test-cmd "squire-$RANDOM" "$SCRIPT_DIR/selftest/squire.sh"
}

init-tracker () {
   mkdir -p $BABTIN_FAIL_DIR
   mkdir -p $RUNNING_DIR 
   # Not really used anywhere in script... yet.
   # If used anywhere else, pull into a global.
   mkdir -p $SCRIPT_DIR/tracker/triaged
   mkdir -p $SCRIPT_DIR/tracker/resolved
}

main () {
   local ITERATIONS=0
   if [ "$1" == "--selftest" ]; then
      export SELFTEST=1
   elif [ "$1" == "--iters" -o "$1" == "--iter" ]; then
      ITERATIONS=$2
   fi
   shopt -s nullglob

   if [ -z $BABTIN_FAIL_DIR ]; then
      export BABTIN_FAIL_DIR=$SCRIPT_DIR/tracker/fails/babtin.$$
      mkdir -p $BABTIN_FAIL_DIR
      echo "Using default tracker/fails for failures"
   else
      echo "Using $BABTIN_FAIL_DIR for failures"
   fi

   # Triage mode...
   if [ "$1" == "--triage" ]; then
      echo "Triaging fails directory..."
      pushd "`pwd`" > /dev/null
      cd $BABTIN_FAIL_DIR
      for f in ./*
      do
         if [ -f "$f" ]; then
            local summary="`bug-summary-from-log $f`"
            echo "Triaging an occurance of $summary"
            if [ "$summary" != "" ]; then
               mkdir -p $BABTIN_FAIL_DIR/$summary
               mv $BABTIN_FAIL_DIR/$f \
                  $BABTIN_FAIL_DIR/$summary/
            fi
         else 
            echo "$f is not a file"
         fi
      done
      popd > /dev/null
      return 0
   fi

   # Create bug tracking structure
   init-tracker

   # Tree is kind of required.
   if [ "`which tree`" == "" ]; then
      echo "NOTE: Please install tree for a better experience!"
   fi

   # Ctrl-C will show status, quick double Ctrl-C will
   # kill the tester.
   trap handle-sigint SIGINT

   # Init our tester's working dir.
   init-working-dir

   # Run tester until killed with double SIGINT
   export SECONDS=0
   . $SCRIPT_DIR/sandbox.sh
   if [ $SELFTEST == 0 ]; then
      tester-begin 
      begin_code=$?
      if [ $begin_code != 0 ]; then
         echo "tester-begin returned non-zero... exiting $begin_code"
         exit $begin_code
      fi
   fi

   # Begin testing.
   do-title
   local iters=$ITERATIONS
   while :
   do
      if [ -f /tmp/BABTIN_DIE ]; then
         echo "Exiting due to /tmp/BABTIN_DIE flag set"
         return
      fi
      # Practice with Squire tester tester.
      if [ $SELFTEST == 1 ]; then
         export BABTIN_FAIL_DIR=$SCRIPT_DIR/tracker/fails/_babtin_selftest
         test-squire
      else
         if [ ! -z $ITERATIONS ]; then
            assert-integer "$FUNCNAME" "$LINENO" "$iters" "iters"
            if [ $iters -eq 0 ]; then
               # End testing
               break
            fi
         fi
         # If they dare to change running test code,
         # try and helpfully start running it on next iteration...
         . $SCRIPT_DIR/sandbox.sh
         printf "[iter:%s] " "$iters"
         tester-next-test $* 
         if [ ! -z $ITERATIONS ]; then
            assert-integer "$FUNCNAME" "$LINENO" "$iters" "ITERATIONS"
            iters=$((iters-1))
         fi
      fi
   done

   if [ ! -z $BABTIN_TEST_FAIL ]; then
      echo "Babtin: I heard at least one test failed..."
      do-summary
      exit 1
   else
      echo "Babtin: PASSED A BARRAGE OF TESTS!"
      do-exit 0
   fi
}

# Run!
source $SCRIPT_DIR/lib.sh
main $*
