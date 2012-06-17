declare -ag CLEANUP=()
declare -Ag LOADEDLIBS=()

#These files should be sources from global context.
source "$ldir/io.sh" || { echo "Can't read io.sh file" 2>&1; exit 1; }
source "$ldir/colors.sh" || { echo "Can't read colors.sh file" 2>&1; exit 1; }

LOADEDLIBS+=([util]=1 [io]=1 [colors]=1)

source_file ()
{
   if [[ -r "$1" ]]
   then
      source "$1" > /dev/null 2>&1 || { echo "$2"; exit 1; }
   else
      echo "$2"
      exit 1
   fi
}

# Called on exit
# CLEANUP is an array of commands to be run at exit.
cleanup ()
{
   local -a param
   
   if [[ $# -eq 2 ]]
   then
      param="${!1}"
   elif [[ $# -gt 2 ]]
   then
      error 'wrong aragument list'
      return 1
   fi
   
   for i in "${CLEANUP[@]}" "${param[@]}"
   do
      eval "$i"
   done
}

trap cleanup EXIT

unexpected_cleanup ()
{
   local -a param="${!1}"
   for i in "${param[@]}"
   do
      eval "$i"
   done
   exit 1
}

# Load library but never reload twice the same lib
loadlibrary ()
{
   while [[ $1 ]]
   do
      (( LOADEDLIBS[$1] )) && { shift; continue; }
      if [[ ! -r "${ldir}/${1}.sh" ]]
      then
         error "${1}.sh file is missing"
         return 1
      fi
      source "${ldir}/${1}.sh" || warning "problem in ${1}.sh library"
      LOADEDLIBS[$1]=1
      shift
   done
}

check_cmd_is_avail?()
{
   type -p "$1" > /dev/null 2>&1
}

# Check directory write permissions and set a cannonical name
# check_dir ($var)
#   $var : name of variable containing directory
check_dir_wr ()
{
   [[ ! -d "${!1}" ]] && { error "${!1} is not a directory"; return 1; }	
   [[ ! -w "${!1}" ]] && { error "${!1} is not writable"; return 2; }	
   eval $1'="$(readlink -e "${!1}")"'	# get cannonical name
   return 0
}
check_dir ()
{
   [[ ! -d "${!1}" ]] && { error "${!1} is not a directory"; return 1; }	
   eval $1'="$(readlink -e "${!1}")"'	# get cannonical name
   return 0
}


augmented_mkdir ()
{
   local dir="$1"
   
   if [[ ! -d "$dir" ]]
   then
      while [[ -n "${dir%/*}" ]]
      do
         dir="${dir%/*}"
         if [[ -d "$dir" ]]
         then
             if [[ -w "$dir" ]]
             then
                mkdir -m 755 -p "$1" || exit 1
             else
                act "$1 directory creation" run_su mkdir -m 700 -p "'$1'" || exit 2
             fi
             return 0
         fi
      done
      act "$1 directory creation" run_su mkdir -m 700 -p "'$1'" || exit 3
   fi
}
