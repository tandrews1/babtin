#!/usr/bin/env bash

#
# "Because A Bash Tester Is Needed"
#
# Taylor Hartley Andrews 
# MIT SDM / Cybersecurity at Sloan 
# 6.824 Distributed Systems
#

VERSION=1.0
# Current directory of this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKING_DIR=/tmp/babtin.$$
WORKING_TOTAL_PASS_FILE=/tmp/babtin.$$/status/total_pass
WORKING_TOTAL_FAIL_FILE=/tmp/babtin.$$/status/total_fail
WORKING_DICE_1_FILE=/tmp/babtin.$$/control/race_die
WORKING_SIGINT_FILE=/tmp/babtin.$$/control/sigint

get-test-log () {
   local name=$1
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$name" "no name given"
   # For now, just use the test name with a random number appended
   local file_name="$name"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$file_name" "file name empty"
   echo /tmp/$file_name.$RANDOM
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
   echo "`io-color-start green`Sir Babtin v$VERSION "
   do-graphic
   echo "`io-color-stop green`"
   echo "WORKING_DIR =$WORKING_DIR"
   echo "Ctrl-C for overall testing status... double Ctrl-C to exit."
   echo "Running with race check die rolls $BABTIN_FIRST_DICE/6"
   echo "Testing..."
}

dump-env () {
   echo "BABTIN_TEST_PASS=$BABTIN_TEST_PASS"
   echo "BABTIN_TEST_FAIL=$BABTIN_TEST_FAIL"
   echo "BABTIN_FIRST_DICE=$BABTIN_FIRST_DICE"
   echo "SIGINT_SKIP=$SIGINT_SKIP"
}

# Sync state to disk from env.
do-env-export () {
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
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$BABTIN_FIRST_DICE" "die empty"
   mbs-assert-not-empty "$FUNCNAME" "$LINENO" "$SIGINT_SKIP" "sigint empty"
   echo $BABTIN_TEST_PASS > $passes_file   && \
      echo $BABTIN_TEST_FAIL > $fails_file && \
      echo $BABTIN_FIRST_DICE > $die_1_file     && \
      echo $SIGINT_SKIP > $sigint_file 
   mbs-assert-zero "$FUNCNAME" "$LINENO" "$?" "save failed"
}

# Sync state from disk into env.
do-env-import () {
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
   local race_die="`cat $die_1_file`"
   local sigint_status="`cat $sigint_file`"
   mbs-assert-integer "$FUNCNAME" "$LINENO" "$passes" "passes not int"
   mbs-assert-integer "$FUNCNAME" "$LINENO" "$fails" "fails not int"
   mbs-assert-integer "$FUNCNAME" "$LINENO" "$race_die" "die 1 not int"
   export BABTIN_TEST_PASS=$passes   && \
      export BABTIN_TEST_FAIL=$fails &&
      export BABTIN_FIRST_DICE=$race_die     &&
      export SIGINT_SKIP=$sigint_status
   mbs-assert-zero "$FUNCNAME" "$LINENO" "$?" "import failed"
}

handle-sigint () {
   do-env-import   
   do-summary
   trap - SIGINT
   sleep 4
   echo "Resuming testing..."
   export SIGINT_SKIP=1
   do-env-export
}

do-summary () {
   local time="`time-seconds-to-human $SECONDS`"
   do-env-import
   echo ""
   echo ""
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
   echo ""
}

init-working-dir () {
   mkdir -p $WORKING_DIR/status
   echo 0 > $WORKING_TOTAL_PASS_FILE
   echo 0 > $WORKING_TOTAL_FAIL_FILE
   mkdir -p /tmp/babtin.$$/control
   echo $BABTIN_FIRST_DICE > $WORKING_DICE_1_FILE
   echo 0 > $WORKING_SIGINT_FILE
}

#
# Searches common strings like ASSERT, error, fail, exception,
# and tries to smash out a single_underscored_summary as a rough summary of
# the error, potentially for a file or directory name.
#
# TODO remove debug statements
#
bug-summary-from-log () {
   local logfile="$1"
   mbs-assert-file "$FUNCNAME" "$LINENO" "$logfile" "arg1 log"
   local search_regex="assert[^a-zA-Z]\|fail[^a-zA-Z]\|error[^a-zA-Z]"
   #echo "searching"
   #echo "grep -m 1 \"$search_regex\" -i $logfile"
   local search_result="`grep -m 1 \"$search_regex\" -i $logfile`"
   if [ "$search_result" != "" ]; then
      local error_regex=".*assert[^a-zA-Z]\|.*fail[^a-zA-Z]\|.*error[^a-zA-Z]"
      #echo "echo \"$search_result\" |sed -e \"s/$error_regex//i\""
      local error_grab="`echo \"$search_result\" \
         |sed -e \"s/$error_regex//i\"`"
      local smash_regex="[^A-Za-z0-9._-]"
      #echo "smashin"
      #echo "echo \"$error_grab\" |sed -e s/\"$smash_regex\"/_/g"
      local first_try="`echo \"$error_grab\" \
         |sed -e s/\"$smash_regex\"/_/g`"
      echo $first_try
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
   local summary_safe="`basename $summary`"
   if [ "$summary" != "" ]; then
      if [ ! -d "$SCRIPT_DIR/fails/$summary" ]; then
         io-hey "NEW BUG: $summary"
         mkdir -p "$SCRIPT_DIR/fails/$summary"
      else 
         echo "Another occurance of $summary"
      fi
      mv $logfile "$SCRIPT_DIR/fails/$summary"
   else
      echo "Could not auto-triage failure :("
   fi
   tree $SCRIPT_DIR/fails
   do-env-import
   #TODO collapse at some point
   local fails=$BABTIN_TEST_FAIL
   fails=$((fails+1))
   export BABTIN_TEST_FAIL=$fails
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
   #TODO collapse at some point
   local passes=$BABTIN_TEST_PASS
   passes=$((passes+1))
   export BABTIN_TEST_PASS=$passes
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
   tester-test-cmd "squier-$RANDOM" "$SCRIPT_DIR/squier.sh"
}

main () {
   shopt -s nullglob
   # Use MBS for testing until util functions inlined...
   source $MBS_ROOT_DIR/core/mbs.sh > /dev/null
 
   # Create bug tracking structure
   mkdir -p $SCRIPT_DIR/fails
   mkdir -p $SCRIPT_DIR/triaged
   mkdir -p $SCRIPT_DIR/resolved

   # Triage mode...
   if [ "$1" == "--triage" ]; then
      echo "Triaging fails directory..."
      pushd "`pwd`" > /dev/null
      cd $SCRIPT_DIR/fails
      for f in ./*
      do
         if [ -f "$f" ]; then
            local summary="`bug-summary-from-log $f`"
            echo "Triaging an occurance of $summary"
            if [ "$summary" != "" ]; then
               mkdir -p $SCRIPT_DIR/fails/$summary
               mv $SCRIPT_DIR/fails/$f \
                  $SCRIPT_DIR/fails/$summary/
            fi
         else 
            echo "$f is not a file"
         fi
      done
      popd > /dev/null
      return 0
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
   tester-begin 
   while :
   do
      # Practice on Squier tester tester.
      if [ "$1" == "--selftest" ]; then
         test-squier
      else
         . $SCRIPT_DIR/sandbox.sh
         tester-next-test $*
      fi
   done
}

# Run!
main $*
