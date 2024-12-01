#!/bin/bash
echo "Taildrop transfer"
echo "-----------------"
if [ "$1" = "r" ]; then 
    echo "-> Receive option selected"
    echo
    echo "IMPORTANT NOTE:"
    echo "1. Any files that have already been received to the Taildrop directory will be immediately transferred to ~/Downloads"
    echo
    echo "2. If there are no files in the Taildrop directory, the transfer will be initiated when"
    echo "the first file is uploaded (in this case please go to the other device and initiate the transfer)"
    echo
    if [ ! -d ~/Downloads ]; then
      echo "Creating ~/Downloads directory..."
      mkdir ~/Downloads
      echo
    fi
    echo "Initiating transfer..."
    echo
    if sudo tailscale file get ~/Downloads; then
      echo "Transfer complete - new directory listing of ~/Downloads is as follows:"
      sudo chown -R $USER:$USER ~/Downloads
      chmod -R 755 ~/Downloads
      echo
      ls -alh ~/Downloads
      echo
    else
      echo
      echo "Error with transfer - see above"
    fi
elif [ "$1" = "s" ]; then 
    echo "-> Send option selected"
    echo
    if [ -z "$2" ]; then
      echo "No file path provided. Please provide the file path as the second argument."
      exit 1
    fi

    file_path="$2"
    if [ ! -f "$file_path" ]; then
      echo "File not found: $file_path"
      exit 1
    fi

    echo "Fetching list of online devices from Tailscale..."
    echo
    # Get the list of online devices, stopping at the first blank line and filtering out offline devices
    devices=$(tailscale status | awk 'BEGIN {RS=""; FS="\n"} {for (i=1; i<=NF; i++) {if ($i ~ /offline/) continue; if ($i ~ /^#/) exit; print $i}}')
    if [ -z "$devices" ]; then
      echo "No online devices found."
      exit 1
    fi

    # Present the list of online devices to the user
    echo "Online devices:"
    echo "$devices" | nl -w 2 -s '. '
    echo

    # Ask the user to choose a device
    read -p "Enter the number of the device you want to send the file to: " device_number
    chosen_device=$(echo "$devices" | sed -n "${device_number}p" | awk '{print $1}')

    if [ -z "$chosen_device" ]; then
      echo "Invalid selection."
      exit 1
    fi

    # Send the file to the chosen device
    echo "Sending file to $chosen_device..."
    sudo tailscale file cp "$file_path" "$chosen_device:"
    echo "File sent."
else
  echo "No option selected - please use 'r' to receive or 's' to send. If sending files then please also specify the file to send, for example as ./taildrop.sh s /path/to/file"
fi
