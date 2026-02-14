AXIS Tools Folder
=================

This folder is for the Bash version (Axis.sh) only.
The PowerShell version (Axis.ps1) uses plink.exe which goes in the main folder.

For PowerShell Version (Axis.ps1):
----------------------------------
Place plink.exe in the MAIN Axis folder (same folder as Axis.ps1)
Download from: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

For Bash Version (Axis.sh):
---------------------------
Place the following binaries here for self-contained operation:

  - sshpass   (for password authentication)
  - expect    (alternative for password auth)

How to get these binaries for air-gapped systems:

Option 1: Copy from a system that has them installed
  # On a system with internet, install then copy:
  sudo yum install sshpass expect
  cp /usr/bin/sshpass /path/to/usb/
  cp /usr/bin/expect /path/to/usb/
  
  # Then copy to this tools folder

Option 2: Download RPMs and extract
  # Download RPMs on internet-connected system
  yumdownloader sshpass expect
  
  # Extract binaries
  rpm2cpio sshpass-*.rpm | cpio -idmv
  rpm2cpio expect-*.rpm | cpio -idmv

Note: Make sure binaries are executable:
  chmod +x sshpass expect

The Axis.sh script will automatically detect tools in this folder.
