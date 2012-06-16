
printf -v P_INDENT "%*s" ${COLUMNS:-0}

# Fill line ($color_start,$content,$color_end)
echo_fill ()
{
   echo -e "$1${P_INDENT// /$2}$3"
}

# Wrap string
# usage: str_wrap ($indent, $str)
# return: set $strwrap with wrapped content
str_wrap ()
{
   local indent=${1:-0} ; shift
   (( indent > COLUMNS )) && { strwrap="$@"; return 0; }
   strwrap="${P_INDENT:0:$indent}$@"
   (( ${#strwrap} < COLUMNS-indent-1 )) && return 0 || { strwrap=""; set -- $@; }
   local i=0 k strout=""
   while [[ $1 ]]
   do
      strout+="$1 "
      (( i+=${#1}+1 ))
      k=${#2}
      if (( k && (i%COLUMNS)+indent+k>COLUMNS-1 )); then
         strwrap+="${P_INDENT:0:$indent}${strout}\n"
         strout=""
         i=0
      fi
      shift
   done
   strwrap+="${P_INDENT:0:$indent}${strout}"
}

echo_wrap ()
{
   local strwrap
   str_wrap "$1" "$2"
   echo -e "$strwrap"
}

echo_wrap_next_line () 
{
   echo -en "$1"; shift
   local len=$1; shift
   local i=0 strout="" strwrap
   for str in "$@"
   do
      str_wrap $len "$str"
      (( i++ )) || strwrap=${strwrap##*( )}
      strout+="${strwrap}\n"
   done
   echo -en "$strout"
}

CLEANUP+=("tput sgr0")

_showmsg() { echo -en "${1}==> ${2}${white}${bold}${3}${reset}" 1>&2; }
msg() { _showmsg "$green" "" "${*}\n"; }
msgs() { _showmsg "$blue" 'START: ' "${*}\n"; }
msgf() { _showmsg "$magenta" 'FINISH: ' "${*}\n"; }
warning() { _showmsg "$yellow" 'WARNING: ' "${*}\n"; }
error() { _showmsg "$red" 'ERROR: ' "${*}\n"; return 1; }
