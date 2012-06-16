loadlibrary colors

toend=$(tput hpa ${COLUMNS})$(tput cub 6)

show_progress ()
{
   local m=${1}
   local l=""
   local n=0
   
   while read -r f
   do
      n=$((n + 1))
      # output progress in case the parameter is defined, otherwise show a sandclock
      if [ ${m} -ne 0 ]
      then
         l="${n}/${m}"
      else
         n=$((n % 4))
         case $n in
            0) l="-" ;;
            1) l="\\" ;;
            2) l="|" ;;
            3) l="/" ;;
         esac
      fi
      echo -en "$(tput sc)$(tput hpa ${COLUMNS})$(tput cub ${#l})${l}$(tput rc)"
   done
   # delete progress output
   printf "$(tput sc)$(tput hpa ${COLUMNS})$(tput cub ${#l})%${#l}s$(tput rc)"
}

show_status ()
{
   local stderr=$(cat)
   # the last line contains the exit code of the action
   local result=$(echo "$stderr" | tail -n 1)
   # strip the result from stderr
   stderr=$(echo "$stderr" | sed -ne '$q;p')
   if [[ ${result} -ne 0 ]]
   then
      echo -e "${bold}${red}${toend}[FAIL]"
   else
      echo -e "${bold}${green}${toend}[DONE]"
   fi
   echo -ne "${reset}"
   [[ -n "${stderr}" ]] && echo -e "\n${stderr}"
   return ${result}
}

fake_info ()
{
   local -i status=$?
   if [[ $# -ne 0 ]]
   then
      status=$1
   fi
   
   if [[ $status -ne 0 ]]
   then
      echo false
   else
      echo true
   fi
}

#1 - description
#2 - progress_bar behaviour
#@ - command
action ()
{
   local max_progress=${3}
   local arg=''
   local -a cmd
   
   tput el1
   tput hpa 0
   
   printf -v line '%*s' $(( $1 + 1 ))
   
   echo -ne "${bold}${yellow}${line// / *}${reset} ${bold}${2}${reset}"
    
   exec 3>&2 4>&1
   {
      (eval "${@:4}"; echo $? 1>&2) 3>&- | show_progress ${max_progress} 2>&3 3>&-
   } 2>&1 1>&4 4>&- | show_status 3>&- 4>&-
   return $?
}

iact ()
{
   action "$1" "$2" 0 "${@:3}"
}

act ()
{
   action 0 "$1" 0 "${@:2}"
}

act1 ()
{
   action 1 "$1" 0 "${@:2}"
}

act2 ()
{
   action 2 "$1" 0 "${@:2}"
}
