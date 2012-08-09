
# Note that you should directly modify the file.

export_filter ()
{
   local names="$1"
   local definitions="$2"
  
   # Removal of __init functions.
   sed -i -e '/[^[:alnum:]_]__init\([^[:alnum:]_]\|$\)/d' "$definitions"
   # IRQ handlers. Not sure about excluding them.
   # This regexp not reliable enough. Because we can't check parameters at this stage.
   # sed -i -e '/\(^\|[^[:alnum:]_]\)irqreturn_t\([^[:alnum:]_]\|$\)/d' "$inline_definitions"
}

alias inline_filter=export_filter

