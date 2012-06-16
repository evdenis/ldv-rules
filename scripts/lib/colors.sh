bold=$(tput bold)

black=$(tput setf 0)
blue=$(tput setf 1)
green=$(tput setf 2)
cyan=$(tput setf 3)
red=$(tput setf 4)
magenta=$(tput setf 5)
yellow=$(tput setf 6)
white=$(tput setf 7)

reset=$(tput sgr0)

export COLUMNS=$(tput cols)
trap "COLUMNS=$(tput cols)" WINCH


