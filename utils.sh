#!/bin/bash

function print_colors() {
  local text="$1"
  local i

  # Foreground colors
  for ((i = 30; i <= 37; i++)); do
    echo -e "\e[${i}m${text} Foreground Color ${i}\e[0m"
  done

  # Bright foreground colors
  for ((i = 90; i <= 97; i++)); do
    echo -e "\e[${i}m${text} Bright Foreground Color ${i}\e[0m"
  done

  # Background colors
  for ((i = 40; i <= 47; i++)); do
    echo -e "\e[${i}m${text} Background Color ${i}\e[0m"
  done

  # Bright background colors
  for ((i = 100; i <= 107; i++)); do
    echo -e "\e[${i}m${text} Bright Background Color ${i}\e[0m"
  done

  # Other text formatting options
  echo -e "\e[1m${text} Bold Text\e[0m"
  echo -e "\e[4m${text} Underlined Text\e[0m"
  echo -e "\e[5m${text} Blinking Text\e[0m"
  echo -e "\e[7m${text} Inverted Colors\e[0m"
  echo -e "\e[9m${text} Crossed-out Text\e[0m"
}

# Check the argument passed and call the corresponding function
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <function_name>"
  echo "Available functions:"
  declare -F | awk '{print $3}'
  exit 1
fi

case "$1" in
"print_colors")
  print_colors
  ;;
"function_two")
  function_two
  ;;
"function_three")
  function_three
  ;;
*)
  echo "Unknown function: $1"
  exit 1
  ;;
esac
