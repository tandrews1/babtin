#!/usr/bin/env bash

#
# "Because A Bash Tester Is Needed"
#
# Taylor Hartley Andrews 
# MIT SDM & Cybersecurity at Sloan 
# 6.824 Distributed Systems
#

VERSION=0.6.5
# Current directory of this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Files for syncing state to disk for eventual sharing between processes
WORKING_DIR=/tmp/babtin.$$
WORKING_TOTAL_PASS_FILE=/tmp/babtin.$$/status/total_pass
WORKING_TOTAL_FAIL_FILE=/tmp/babtin.$$/status/total_fail
WORKING_DICE_1_FILE=/tmp/babtin.$$/control/first_dice
WORKING_SIGINT_FILE=/tmp/babtin.$$/control/sigint
FAIL_DIR=$SCRIPT_DIR/tracker/fails
RUNNING_DIR=$SCRIPT_DIR/tracker/running/pid.$$/
SELFTEST=0

get-test-log () {
   local name=$1
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$name" \
      "no name given"
   # For now, just use the test name with a random number appended
   local file_name="$name"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$file_name" \
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
   do-graphic
   echo "`io-color-stop green`"
   echo "SELFTEST                 =$SELFTEST"
   echo "WORKING_DIR              =$WORKING_DIR"
   echo "BABTIN_1ST_DICE    roll <=$BABTIN_1ST_DICE/6"
   echo "Ctrl-C to pause and babtin cmd prompt"
   echo ""
}

dump-env () {
   echo "BABTIN_TEST_PASS=$BABTIN_TEST_PASS"
   echo "BABTIN_TEST_FAIL=$BABTIN_TEST_FAIL"
   echo "BABTIN_1ST_DICE=$BABTIN_1ST_DICE"
   echo "SIGINT_SKIP=$SIGINT_SKIP"
}

# Sync state to disk from env.
do-env-export () {
   #TODO wait on .lck file
   #TODO acquire .lck file
   local passes_file="$WORKING_TOTAL_PASS_FILE"
   local fails_file="$WORKING_TOTAL_FAIL_FILE"
   local die_1_file="$WORKING_DICE_1_FILE"
   local sigint_file="$WORKING_SIGINT_FILE"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$passes_file" "pass file not found"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$fails_file" "fail file not found"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$die_1_file" "fail file not found"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$sigint_file" "sigint file not found"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$BABTIN_TEST_PASS" "passes empty"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$BABTIN_TEST_FAIL" "fails empty"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$BABTIN_1ST_DICE" "die empty"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$SIGINT_SKIP" "sigint empty"
   #TODO release .lck file
   echo $BABTIN_TEST_PASS > $passes_file   && \
      echo $BABTIN_TEST_FAIL > $fails_file && \
      echo $BABTIN_1ST_DICE > $die_1_file     && \
      echo $SIGINT_SKIP > $sigint_file 
   mbs-assert-zero "$FUNCNAME" "$LINENO" "$?" "save failed"
}

# Sync state from disk into env.
do-env-import () {
   #TODO wait on a .lck file
   #TODO acquire a .lck file
   local passes_file="$WORKING_TOTAL_PASS_FILE"
   local fails_file="$WORKING_TOTAL_FAIL_FILE"
   local die_1_file="$WORKING_DICE_1_FILE"
   local sigint_file="$WORKING_SIGINT_FILE"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$passes_file" "pass file not found"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$fails_file" "fail file not found"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$die_1_file" "die 1 file not found"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$sigint_file" "sigint file not found"
   local passes="`cat $passes_file`"
   local fails="`cat $fails_file`"
   local first_dice="`cat $die_1_file`"
   local sigint_status="`cat $sigint_file`"
   #TODO release .lck file
   mbs-assert-integer "$FUNCNAME" "$LINENO" "$passes" "passes not int"
   mbs-assert-integer "$FUNCNAME" "$LINENO" "$fails" "fails not int"
   mbs-assert-integer "$FUNCNAME" "$LINENO" "$first_dice" "die 1 not int"
   export BABTIN_TEST_PASS=$passes   && \
      export BABTIN_TEST_FAIL=$fails && \
      export BABTIN_1ST_DICE=$first_dice && \
      export SIGINT_SKIP=$sigint_status
   mbs-assert-zero "$FUNCNAME" "$LINENO" "$?" "import failed"
}

do-exit () {
   echo "Exiting..."
   echo "In-progress test output left at $RUNNING_DIR"
   rm -r $WORKING_DIR && exit 0 
   # If remove failed exit with status 1. Kind of hacky but saves some lines...
   exit 1
}

handle-sigint () {
   do-env-import   
   do-summary
   trap handle-sigint SIGINT
   local cmd=""
   echo ""
   echo -n "e to exit, enter to continue> "
   read cmd
   if [ "$cmd" == "e" -o "$cmd" == "E" -o "$cmd" == "exit" ]; then
      do-exit 
   fi
   echo "Resuming testing..."
   export SIGINT_SKIP=1
   do-env-export
}

do-summary () {
   local time="`time-seconds-to-human $SECONDS`"
   do-env-import
   if [ "`which tree`" != "" ]; then
      echo ""
      tree -ChDdt  $FAIL_DIR
   fi
   #ls -ltrh $FAIL_DIR
   echo -en "`io-color-start green`$BABTIN_TEST_PASS pass streak ($time)`io-color-stop green` | "
   if [ $BABTIN_TEST_FAIL -gt 0 ]; then
      echo -en "`io-color-start red`"
   fi 
   echo -en "$BABTIN_TEST_FAIL fail(s)"
   if [ $BABTIN_TEST_FAIL -gt 0 ]; then
      echo -e "`io-color-stop red`"
   else 
      echo ""
   fi
   echo "WORKING_DIR=$WORKING_DIR"
   tester-summary
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
   mbs-assert-file "$FUNCNAME" "$LINENO" "$logfile" "arg1 log"
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
   local search_regex="assert[^a-zA-Z]\|fail[^a-zA-Z]\|error[^a-zA-Z]\|exception[^a-zA-Z]\|panic[^a-zA-Z]"
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
   mbs-assert-file "$FUNCNAME" "$LINENO" "$logfile" "arg1 log"
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
      if [ ! -d "$FAIL_DIR/$summary" ]; then
         echo -e "`io-color-start red`NEW BUG: $summary`io-color-stop red`"
         mkdir -p "$FAIL_DIR/$summary"
      else 
         echo "It's another $summary"
      fi
      mv $logfile "$FAIL_DIR/$summary"
   else
      echo "Could not auto-triage failure :("
      mkdir -p "$FAIL_DIR/unknown"
      mv $logfile "$FAIL_DIR/unknown"
   fi
   do-env-import
   export BABTIN_TEST_FAIL=$((BABTIN_TEST_FAIL+1))
   # Start the passing streak over...
   export BABTIN_TEST_PASS=0
   export SECONDS=0
   do-env-export
}

test-pass () {
   local logfile="$1"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$logfile" "log file empty"
   echo "`io-color-start green`PASS `io-color-stop green`"
   do-env-import
   export BABTIN_TEST_PASS=$((BABTIN_TEST_PASS+1))
   do-env-export
   rm $logfile
}

tester-test-cmd () {
   local name="$1"
   local cmd="$2"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$name" "arg1 empty"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$cmd" "arg2 empty"
   local logfile="`get-test-log $name`"
   printf "(%-14s) %16s: " "`time-seconds-to-human $SECONDS`" "$name"
   $cmd &> $logfile
   cmd_exit=$?
   # If we handled a sigint and returned, then just abort the current test...
   if [ $cmd_exit != 0 ]; then
      do-env-import
      mbs-assert-integer "$FUNCNAME" "$LINENO" "$SIGINT_SKIP" \
         "SIGINT skip not synced right"
      if [ $SIGINT_SKIP == 1 ]; then
         trap handle-sigint SIGINT
         export SIGINT_SKIP=0
         do-env-export
         echo "Starting a new test..."
         return 130
      fi
      test-fail "$logfile"
   else 
      test-pass "$logfile"
   fi
}

test-squier () {
   tester-test-cmd "squier-$RANDOM" "$SCRIPT_DIR/selftest/squier.sh"
}

init-tracker () {
   mkdir -p $FAIL_DIR
   mkdir -p $RUNNING_DIR 
   # Not really used anywhere in script... yet.
   # If used anywhere else, pull into a global.
   mkdir -p $SCRIPT_DIR/tracker/triaged
   mkdir -p $SCRIPT_DIR/tracker/resolved
}

main () {
   if [ "$1" == "--selftest" ]; then
      export SELFTEST=1
   fi
   shopt -s nullglob
   # Use MBS for testing until util functions inlined...
   source $MBS_ROOT_DIR/core/mbs.sh > /dev/null
 
   # Create bug tracking structure
   init-tracker

   # Triage mode...
   if [ "$1" == "--triage" ]; then
      echo "Triaging fails directory..."
      pushd "`pwd`" > /dev/null
      cd $FAIL_DIR
      for f in ./*
      do
         if [ -f "$f" ]; then
            local summary="`bug-summary-from-log $f`"
            echo "Triaging an occurance of $summary"
            if [ "$summary" != "" ]; then
               mkdir -p $FAIL_DIR/$summary
               mv $FAIL_DIR/$f \
                  $FAIL_DIR/$summary/
            fi
         else 
            echo "$f is not a file"
         fi
      done
      popd > /dev/null
      return 0
   fi

   # Tree is kind of required.
   if [ "`which tree`" == "" ]; then
      echo "NOTE: Please install tree for a better experience!"
   fi

   # Ctrl-C will show status, quick double Ctrl-C will
   # kill the tester.
   trap handle-sigint SIGINT

   # Init our tester's working dir.
   init-working-dir

   # Begin testing.
   do-title

   # Run tester until killed with double SIGINT
   export SECONDS=0
   . $SCRIPT_DIR/sandbox.sh
   if [ $SELFTEST == 0 ]; then
      tester-begin 
   fi
   while :
   do
      # Practice with Squier tester tester.
      if [ $SELFTEST == 1 ]; then
         test-squier
      else
         # If they dare to change running test code,
         # try and helpfully start running it on next iteration...
         . $SCRIPT_DIR/sandbox.sh
         tester-next-test $*
      fi
   done
}

# Run!
main $*
