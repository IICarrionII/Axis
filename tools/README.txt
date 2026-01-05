AXIS Tools Folder
=================

Place the following binaries here for self-contained operation:

For Linux (RHEL/CentOS):
  - sshpass   (copy from: /usr/bin/sshpass after installing with yum)
  - expect    (copy from: /usr/bin/expect after installing with yum)

How to get these binaries for air-gapped systems:
-------------------------------------------------

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

The script will automatically detect tools in this folder.
