

#
# io-color-start -- 
#
#    Echo codes to make colors.
#
io-color-start () {
   local color=$1
   if [ ! -z $BABTIN_COLORS ]; then
      if [ "$color" == "red" ]; then
         echo "\e[00;31m"
      elif [ "$color" == "green" ]; then
         echo -e "\e[32m"
      else
         io-exception "Unknown color '$1'"
      fi
   fi
}

#
# io-color-stop --
#
#    Echo stop color codes.
#
io-color-stop () {
   local color=$1
   if [ ! -z $BABTIN_COLORS ]; then
      if [ "$color" == "red" ]; then
         echo "\e[00m"
      elif [ "$color" == "green" ]; then
         echo -e "\e[39m"
      else
         io-exception "Unknown stop color '$1'"
      fi
   fi
}

#
# io-exception --
#
#    Show something bad happened. Encourage user to terminate execution.
#
io-exception () {
   local msg=$1
   local hint=$2
   if [ "`uname`" != "Darwin" ]; then
      echo -e "`io-color-start red`EXCEPTION:`io-color-stop red` $msg ($hint)"
      echo -e "Press ctrl-c to break, or else to continue (not recommended)."
   else
      echo -e "EXCEPTION: $msg $hint"
      echo -e "Press ctrl-c to break, or else to continue (not recommened)."
   fi
   # pause
   read -p ""
}

#
# assert-integer --
#
#    Assert that a given value is a positive integer value.
#
#    usage: 'assert-integer $FUNCNAME $LINENO <val>'
#       ex: 'assert-integer $FUNCNAME $LINENO <val>'
assert-integer () {
   local func="$1"
   local line="$2"
   local val="$3"
   if ! [[ "$val" =~ ^[0-9]+$ ]] ; then
      io-exception "$func:$line val '$val' is not an integer and it should be!"
   fi
}

# 
# assert-zero --
#
#    Expect a zero value otherwise execption.
#
assert-zero () {
   local function="$1"
   local lineno="$2" 
   local val="$3"
   local msg="$4"
   if [ "$val" != "0" ]; then
      io-exception "assert-not-zero@$function:$lineno:" "$msg"
   fi
}

#
#  assert-file --
#
#    Assert that a given file exists.
#
#    usage: 'assert-file $FUNCNAME $LINENO <file> <hint>'
#       ex: 'assert-file $FUNCNAME $LINENO <file> <hint>'
#
assert-file () {
   local func="$1"
   local line="$2"
   local file="$3"
   local hint="$4"
   if [ "$func" == "" ]; then
      io-exception "assert-file: (Arg1 is blank)" "$hint"
   fi
   if [ "$line" == "" ]; then
      io-exception "$func:$line assert-file: (Arg2 is blank)" "$hint"
   fi
   if [ "$file" == "" ]; then
      io-exception "$func:$line: assert-file: (Arg3 is blank)" "$hint"
   fi
   if [ "$hint" == "" ]; then
      io-exception "$func:$line: assert-file: (Arg4 is blank)"
   fi
   if [ ! -f "$file" ] ; then
      io-exception "$func:$line: assert-file FAIL:" "$hint"
   fi
}

#
# assert-not-empty -- 
#
#    Expect a non-empty value otherwise exception.
#    usage: 'assert-not-empty <$FUNCTION> <$LINENO> <val> [<msg>]'
#
assert-not-empty () {
   local function="$1"
   local lineno="$2"
   local val="$3"
   local msg="$4"
   if [ "$val" == "" ]; then
      io-exception "assert-not-empty@$function:$lineno:" "$msg"
   fi
}

#
# time-seconds-to-human --
#
#    Convert seconds to a human readable string describing the duration.
#
#    Based on http://stackoverflow.com/questions/12199631/
#                convert-seconds-to-hours-minutes-seconds
#
#    usage: 'time-seconds-to-human <seconds>'
#       ex: 'time-seconds-to-human 124567'
#
time-seconds-to-human () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d "$hour"h "$min"m "$sec"s
}


