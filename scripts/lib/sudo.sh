
if check_cmd_is_avail? sudo
then
   SUDO="$(which sudo)"
else
   SUDO=''
fi

# Check if sudo is allowed for given command
is_sudo_allowed ()
{
   if [[ -n "$SUDO" ]]
   then
      "$SUDO" -p 'sudo password:' -nl "$@" > /dev/null 2>&1
      if [[ $? -ne 0 ]]
      then
         echo > /dev/tty
         "$SUDO" -p 'sudo password:' -v 2>/dev/tty && "$SUDO" -p 'sudo password:' -l "$@" > /dev/null 2>&1 && return 0
      else
         return 0
      fi
   fi
   return 1
}

fake_sudo ()
{
   local errorfile=$(mktemp -u --tmpdir="$TMPDIR")
   local arg=''
   
   while [[ $1 ]]
   do
      printf -v arg "%q" "$1"
      cmd+=("$arg")
      shift
   done
   for i in 1 2 3
   do
      su --shell="$BASH" --command "${cmd[*]} || { touch '$errorfile' && chown $USER '$errorfile'; }" 2>/dev/tty
      (( $? )) && [[ ! -f "$errorfile" ]] && continue
      [[ -f "$errorfile" ]] && { rm -f "$errorfile"; return 1; }
      return 0
   done
   return 1
}

# Run $* as root using sudo or su
run_su ()
{
   if is_sudo_allowed "$@"
   then
      "$SUDO" -p 'sudo password:' "$@" 2>/dev/tty
   else
      echo > /dev/tty
      fake_sudo "$@"
   fi
}
