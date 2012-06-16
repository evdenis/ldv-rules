
loadlibrary io

manage_config ()
{
   local name='config'
   
   [[ -n "${!1}" ]] && name="${!1}"
   
   if [[ $( echo "$name" | head -c 1 ) != '/' ]]
   then
      if [[ -n "$2" && -r "${2}/${name}" ]]
      then
         name="${2}/${name}"
      else
         if [[ -r "${rdir}/tools/${name}" ]]
         then
            name="${rdir}/tools/${name}"
         else
            error "There is no such \"$name\" config file in tools directory. Please, use path (absolute ot relative) for config file or just the name of preferred config file in tools directory. Filename \"config\" is default one."
            exit 1
         fi
      fi
   fi
   eval "$1"="${name}"
}
