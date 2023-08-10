#!/bin/bash
# Script for modifying file names. Dedicated to lowering or uppercasing file names
# or internally calling sed command with the given sed pattern which will operate on file names.
# Additionally changes may be done with recursion or without it.

# Name of the script without a path
name=`basename $0`

# Set of flag variables
lowerCase=n
upperCase=n
recursive=n
sedPattern=""

# ---------FUNCTIONS--------- #

# Function for printing messages to diagnostic output
alert_msg()
{
    echo "$name: $1" 1>&2
}

# Function for servicing help (-h) flag
help_msg()
{
cat<<EOT 1>&2
    usage:
        $name [-r] [-l|-u] <fir/file names>
        $name [-r] <sed pattern> <dir/file names>
        $name [-h]

    $name correct syntax examples:
        $name -r -l /home/user
        $name -u /home/user/file.txt

    $name incorrect syntax examples:
        $name file.c
        $name -l 's/changeThis/changeTo' /file.c
EOT
}

fileEdit()
{
    if test -f $1
    then
        path=$(dirname "$1")
        filename=$(basename "$1")
        if test $filename = $name
        then
            alert_msg "Script cannot modify its file name"
            return 1
        fi       
        ext="${filename##*.}" 
        if test "$ext" = "$filename" || test ".$ext" = "$filename"
        then
            if test $lowerCase = "y"
            then
                basename=$(echo "$filename"| tr '[:upper:]' '[:lower:]')
            elif test $upperCase = "y"
            then
                basename=$(echo "$filename"| tr '[:lower:]' '[:upper:]')
            elif [ $sedPattern != "" ]
            then
                basename=$(echo "$filename"| sed -r "${sedPattern}")
            fi
            newname="$path/$basename"
        else
            if test $lowerCase = "y"
            then
                basename=$(echo "${filename%.*}"| tr '[:upper:]' '[:lower:]')
            elif test $upperCase = "y"
            then
                basename=$(echo "${filename%.*}"| tr '[:lower:]' '[:upper:]')
            elif [ $sedPattern != "" ]
            then
                basename=$(echo "${filename%.*}"| sed -r "${sedPattern}")
            fi
            newname="$path/$basename.$ext"
        fi

        if [ -e "$newname" ]
        then
            alert_msg "Error: $newname already exists"
        else
            mv "$1" "$newname"
        fi
    fi
}

# ---------Main program--------- #

# Output message if no arguments are given
if test -z "$1"
then
cat<<EOT 1>&2
    modify.sh script is dedicated to modify file names.
    For help on usage of a script use -h flag.
EOT
exit 0
fi

# Parsing flags
while getopts rluh flag; do
    case $flag in
        r)
            recursive=y
        ;;
        l)
            lowerCase=y
            if test $upperCase = "y"
            then
                alert_msg "Error: You can only use of one -l or -u flags at the same time"
                exit 1
            fi
        ;;
        u)
            upperCase=y
            if test $lowerCase = "y"
            then
                alert_msg "Error: You can only use of one -l or -u flags at the same time"
                exit 1
            fi
        ;;
        h) 
            help_msg
            exit 0 
        ;;
    esac
done

# ---Parsing rest of arguments--- #

# Finding sed pattern in arguments
for argument in "$@" 
do
    if !(test -d $argument) && !(test -f $argument)
        then
        if  test "${argument%%/*}" = "s"
        then
            if !(test -z $sedPattern)
            then
                alert_msg "Error: Too many SED patterns were specified"
                exit 1
            fi
            sedPattern="$argument"
            if (test $upperCase = "y" || test $lowerCase = "y")
            then
                alert_msg "Error: Sed pattern cannot be used with -u or -l flag"
                exit 1
            fi
        fi
    fi
done

# Checking if any flag was set
if test $upperCase = "n" && test $lowerCase = "n" && test -z $sedPattern 
then
    alert_msg "Error: None of the editing parameters were specified: [-u|-l] or <sed pattern>"
    exit 1
fi

# Checking if any <directory/file name> was specified
isFile="n"
for file in "$@"
do
    if test -d $file || test -f $file
    then
        isFile="y"
        break
    fi
done

if test $isFile = "n"
then
    alert_msg "Error: No directories of files were specified"
    exit 1
fi

# Parsing directories and files
for file in "$@"
do
    if test -d $file
    then
        if test $recursive = "y"
        then
            find "${file}" -type f -prune -o -name ".*" | while read i; do
                fileEdit $i
            done
        else
            find "${file}" -maxdepth 1 -type f -prune -o -name ".*" | while read i; do
                fileEdit $i
            done
        fi
    elif test -f $file
    then
        fileEdit $file
    fi
done
exit 0