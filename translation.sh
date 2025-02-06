#!/bin/bash
#author: Andrei Lazic
#class: cmpt215

###############################################################################
#                       error checking args / arg count                       #
###############################################################################
#check arg count
if [ $# -ne 3 ]; then
  echo "ERROR: INVALID INPUTS"
  echo "USAGE: ./translationScript.sh [MODE] [SOURCE_FILE.s] [RESULT_FILE.s]"
  exit 1
fi

res=$3
src=$2
mode=$1

#check if file exists
if ! [ -f $src ]; then
  echo "ERROR: GIVEN BINARY DOES NOT EXIST"
  echo "USAGE: ./translationScript.sh [MODE] [SOURCE_FILE.s] [RESULT_FILE.s]"
  exit 1
fi

###############################################################################
#                       mappings for rars / qemu                              #
###############################################################################

declare -A SYS_MAP_RARS=(
	["SYS_printInt"]=1
	["SYS_readInt"]=5
  ["SYS_printChar"]=11
  ["SYS_readChar"]=12
  ["SYS_printStr"]=4
  ["SYS_readStr"]=8
  ["SYS_printFloat"]=2
  ["SYS_readFloat"]=6
  ["SYS_exit"]=93
)

declare -A SYS_MAP_QEMU=(
  ["1"]="SYS_printInt"
  ["5"]="SYS_readInt"
  ["11"]="SYS_printChar"
  ["12"]="SYS_readChar"
  ["4"]="SYS_printStr"
  ["8"]="SYS_readStr"
  ["2"]="SYS_printFloat"
  ["6"]="SYS_readFloat"
  ["93"]="SYS_exit"
)
###############################################################################
#                       translation functions                                 #
###############################################################################
#rars to qemu
q2r() {

  local srcFile=$1
  local resFile="$2"

  # Check if source file exists
  if [[ ! -f "$srcFile" ]]; then
	echo "ERROR: Source file '$srcFile' does not exist!"
	exit 1
  fi

  echo "Converting QEMU format to RARS format..."

  # Step 1: Copy the contents of srcFile to resFile
  cp "$srcFile" "$resFile"

  # Step 2: Apply transformations to resFile:
  #  - Remove leading whitespace for lines starting with '.' (except `.equ` lines)
  #  - Delete lines starting with `.equ`
  sed -i -e 's/^[[:space:]]*\(\.\)/\1/' -e '/^[[:space:]]*\.equ/d' "$resFile"

  sed -i '/\.section .text/ s/\.section .text/\.section\n.text/' "$resFile"


  # Step 3: Replace system calls with corresponding numbers from SYS_MAP_RARS
  for key in "${!SYS_MAP_RARS[@]}"; do
	sed -i "s/${key}/${SYS_MAP_RARS[$key]}/g" "$resFile"
  done

  echo "Conversion done, file name: $resFile"
}


# rars to qemu
# rars to qemu
r2q() {
  local srcFile=$1
  local resFile=$2

  echo "Converting RARS format to QEMU format..."

  # Step 1: Copy the contents of srcFile to resFile
  cp "$srcFile" "$resFile"

  # Step 2: Insert the .equ directives at the top of the file
  sed -i '1s/^/.equ SYS_printInt, 244\n.equ SYS_readInt, 245\n.equ SYS_printChar, 246\n.equ SYS_readChar, 247\n.equ SYS_printStr, 248\n.equ SYS_readStr, 249\n.equ SYS_printFloat, 250\n.equ SYS_readFloat, 251\n.equ SYS_exit, 93\n/' "$resFile"

  # Step 3: Merge `.section` and `.text` into one line
  # This looks for `.section` followed by `.text` and merges them into `.section .text`
  sed -i '/\.section/ {
    N
    s/\.section\n\.text/\.section .text/
  }' "$resFile"

  # Step 4: Replace `li a7, <number>` with `li a7, <syscall_name>` from SYS_MAP_QEMU
  for key in "${!SYS_MAP_QEMU[@]}"; do
    sed -i "s/li a7, $key/li a7, ${SYS_MAP_QEMU[$key]}/g" "$resFile"
  done

  echo "Conversion done, file name: $resFile"
}


###############################################################################
#                       switch case (mode selection)                          #
###############################################################################
#mode handling
case $mode in
  --r2q)
    r2q $src $res
  ;;
  --q2r)
    q2r $src $res
  ;;
  --help)
    echo "USAGE: ./translationScript.sh [MODE] [SOURCE_FILE.s] [RESULT_FILE.s]"
    echo "MODES:\n--r2q\n--q2r"
    exit 1
  ;;
  *)
    echo "ERROR: INVALID MODE SELECTED"
    echo "USAGE:"
    echo "--r2q: rars format to qemu format"
    echo "--q2r: qemu format to rars format"
    exit 1
  ;;
esac

###############################################################################
#                       switch case (mode selection)                          #
###############################################################################
