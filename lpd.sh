#!/bin/bash

###CLEAR VARIABLES
DOWNLOAD_SET=""
DOWNLOADER=""
PKGMAN=""
TEST="0"
# !!!TEST copy this line wherever you need the script to stop in a test
if [ "$TEST" == "1" ] ; then return 0 ; fi
DOWNLOAD_SELECTION=""
UNKNOWN_OPT=""

###SET VARIABLES
DOWNLOAD_DATE="`date +%Y-%m`"
WORKINGDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

###CONFIGURATION
DOWNLOAD_DIRECTORY="$WORKINGDIR/downloads"
LOGFILE="$WORKINGDIR/support/lpd.log"
touch $LOGFILE
CONFIG_FILE="$WORKINGDIR/support/Programs for monthly update.csv"

printlog () {
  echo $1
  echo $1 >> $LOGFILE
  if [ $2 == "failed" ] ; then
    echo $1 >> "$WORKINGDIR/logs/failed.txt"
  fi
  }

###OPTIONS PROCESSING
SKIP_ARG="0"
for ARG ; do
  if [ -n != "$ARG" ] ; then
    UNKNOWN_OPT="1"
    if [ "$SKIP_ARG" == "1" ] ; then
      SKIP_ARG="0"
    fi
    if [ "$ARG" == "-h" ] || [ "$ARG" == "--help" ] ; then
      echo "Usage: pdu.sh -i [USER'S INITIALS]... -s [DOWNLOAD SET]... -c -h"
      echo "  -h, --help 			prints this help message"
      echo "  -i, --initials 		Specifies initials to be appended to file names"
      echo "  -s, --set 			allows you to choose from a predefined set of downloads"
      echo "  -c, --configure 		walks you through the configuration process"
      echo "  -r, --reset 			resets all logs"
      echo "Welcome to the Program Downloader Utility (PDU).  This program was created to automatically download programs from the internet using the terminal-based Lynx web browser."
      echo "Configuration files can be found in the support/ directory.  Every URL given in the categories will be downloaded into a matching subfolder.  At this time, only websites from majorgeeks.com are supported, and you will want to put the download page in line, NOT the general information page.  This allows you to choose which mirror you'd like to download.  For all other direct downloads, you can put them in 'unsorted', and they will be downloaded via wget."
      return 0
    fi
    if [ "$ARG" == "-c" ] || [ "$ARG" == "--configure" ] ; then
      echo "Please enter the path to the folder you would like your new downloads to be dropped off:"
      read DOWNLOAD_DIRECTORY
      UNKNOWN_OPT="0"
      shift
    fi
    if [ "$ARG" == "-i" ] || [ "$ARG" == "--initials" ] ; then
      if [ -z "$2" ] ; then
	echo "Please specify initials to be placed on downloads" && return 1
      else
	DOWNLOADER="$2"
	echo "$DOWNLOADER will be appended to filenames."
	UNKNOWN_OPT="0"
	SKIP_ARG="1"
      fi
    fi
    if [ "$ARG" == "-s" ] || [ "$ARG" == "--set" ] ; then
      if [ -z "$2" ] ; then
	echo "Please specify set to download" && return 1
      else
	echo "Downloading $2..."
	DOWNLOAD_SET="$2"
	UNKNOWN_OPT="0"
	SKIP_ARG="1"
      fi
    fi
    if [ "$ARG" == "-r" ] || [ "$ARG" == "--reset" ] ; then
      if [ "`ls $WORKINGDIR/logs/badfiles/`" != "" ] ; then
	rm -f $WORKINGDIR/logs/badfiles/* && echo "files cleared"
      else echo "no files to clear"
      fi
      if [ -f $WORKINGDIR/logs/failed.txt ] ; then
	NOW=`date`
	mv $WORKINGDIR/logs/failed.txt "$WORKINGDIR/logs/failed: $NOW.txt"
	echo "failed.txt archived and cleared."
      else echo "no logs to clear"
      fi
      UNKNOWN_OPT="0"
    fi
    if [ "$ARG" == "-t" ] || [ "$ARG" == "--test" ] ; then
      echo "Test mode!"
      TEST="1"
      UNKNOWN_OPT="0"
    fi
    if [ "$UNKNOWN_OPT" == "1" ] ; then
      echo "unkown option!" && return 1
    fi
  fi
done

###DEPENDENCY CHECK
which rpm > /dev/null 2>&1
if [ "$?" == "0" ] ; then
  PKGMAN="rpm"
  printlog "Package Manager: $PKGMAN"
fi
which apt > /dev/null 2>&1
if [ "$?" == "0" ] ; then
  PKGMAN="apt"
  printlog "Package Manager: $PKGMAN"
fi
if [ -z "$PKGMAN" ] ; then
  echo "Package manager not recognized!  Please make sure rpm or apt are installed and working!" && return 1
fi
depcheck () {
  which "$1" >> /dev/null
  if [ "$?" != "0" ] ; then
    echo "This program requires $1 to be installed in order to run properly.  You can install it by typing:"
    if [ "$PKGMAN" == "apt" ] ; then
      echo "sudo apt-get install $1"
    elif [ "$PKGMAN" == "rpm" ] ; then
      echo #rpm apt-get command here
    else echo "Package manager not recognized!  Please make sure rpm or apt are installed and working!" && return 1
    fi
    echo "Or we can try to install it right now.  Would you like to? (Y/N)"
    UINPUT=0
    read UINPUT # grab first letter of input, upper or lower it, and check for THAT input.  Shorter.
    until [ $UINPUT == "exit" ] ; do
      if [ $UINPUT == "Y" ] || [ $UINPUT == "y" ] || [ $UINPUT == "yes" ] || [ $UINPUT == "Yes" ] || [ $UINPUT == "YES" ] ; then
	sudo apt-get install lynx
	UINPUT="exit"
      elif [ $UINPUT == "N" ] || [ $UINPUT == "n" ] || [ $UINPUT == "no" ] || [ $UINPUT == "No" ] || [ $UINPUT == "NO" ] ; then
	echo "Package install cancelled." && return 0
      else echo "I beg your pardon?"
      fi
    done
  else echo "Dependency check of $1 success"
  fi }

progdownload () {
  mkdir "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$2" > /dev/null 2>&1
  NOW=$(date +"%Y_%m_%d") && printlog "$DOWNLOAD_SET started at $NOW"
  MYNUM="0"
  until [ "$URL" == "exit" ] ; do
    MYNUM=$((MYNUM + 1))
    URL="$(sed ''$MYNUM'q;d' $1)" && echo "$MYNUM) downloading $URL"
    mkdir "$WORKINGDIR/tmp" > /dev/null 2>&1
    cd "$WORKINGDIR/tmp" && pwd
    lynx -cmd_script="$WORKINGDIR/support/mgcmd.txt" --accept-all-cookies $URL && echo "lynx complete!"
    FILE=`(ls | head -n 1)` && echo $FILE
    EXT=`echo -n $FILE | tail -c 3` && echo $EXT
    BAD=`cat "$WORKINGDIR/support/whiteexts.txt" | grep -v "#" | grep -cim1 "$EXT"` && echo $BAD
    if [ -z "$FILE" ] ; then
      printlog "Download incomplete: $URL" "failed"
    else
      until [ -z "$FILE" ] ; do
        if [ $BAD == "0" ] ; then
            printlog "Download $FILE is of unknown type. $URL failed"
            mv "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/$FILE"
        else echo "new file downloaded."
        fi
        mv "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$DOWNLOAD_SET/$FILE"
        FILE=`(ls | head -n 1)`
      done
    fi
    cd "$WORKINGDIR"
  done
  }

###PROGRAM START
cd $WORKINGDIR
depcheck wget
depcheck lynx

mkdir "$DOWNLOAD_DIRECTORY/`date +%Y-%m`" > /dev/null 2>&1
mkdir "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles" > /dev/null 2>&1

if [ -z "$DOWNLOADER" ] ; then
  echo "Please enter your initials:"
  read DOWNLOADER
fi

until [ "$DOWNLOAD_SET" == "exit" ] ; do
  UNKNOWN_OPT="1"
  echo "Which batch would you like to download?"
  echo "all majorgeeks antivirus creative utilities office clear_logs configure exit"
#   DOWNLOAD_SELECTION="All Majorgeeks Wgets Antivirus Creative Utilities Office Clear_logs Configure Exit"
#   select opt in $DOWNLOAD_SELECTION; do
#     DOWNLOAD_SET="$opt"
#   done
  read DOWNLOAD_SET
  if [ "$DOWNLOAD_SET" == "all" ] ; then
    UNKNOWN_OPT="0"
    echo "Downloading $DOWNLOAD_SET ..."
    progdownload "$WORKINGDIR/wgetadrs.txt" "unsorted"
    progdownload "$WORKINGDIR/support/antivirus.txt" "antivirus"
    progdownload "$WORKINGDIR/support/creative.txt" "creative"
    progdownload "$WORKINGDIR/support/utilities.txt" "utilities"
    progdownload "$WORKINGDIR/support/office.txt" "office"
  fi
  if [ "$DOWNLOAD_SET" == "majorgeeks" ]; then
    UNKNOWN_OPT="0"
    echo "Downloading $DOWNLOAD_SET ..."
    progdownload "$WORKINGDIR/support/antivirus.txt" "antivirus"
    progdownload "$WORKINGDIR/support/creative.txt" "creative"
    progdownload "$WORKINGDIR/support/utilities.txt" "utilities"
    progdownload "$WORKINGDIR/support/office.txt" "office"
  fi
  if [ "$DOWNLOAD_SET" == "antivirus" ]; then
    UNKNOWN_OPT="0"
    echo "Downloading $DOWNLOAD_SET ..."
    progdownload "$WORKINGDIR/support/antivirus.txt" "antivirus"
  fi
  if [ "$DOWNLOAD_SET" == "creative" ]; then
    UNKNOWN_OPT="0"
    echo "Downloading $DOWNLOAD_SET ..."
    progdownload "$WORKINGDIR/support/creative.txt" "creative"
  fi
  if [ "$DOWNLOAD_SET" == "utilities" ]; then
    UNKNOWN_OPT="0"
    echo "Downloading $DOWNLOAD_SET ..."
    progdownload "$WORKINGDIR/support/utilities.txt" "utilities"
  fi
  if [ "$DOWNLOAD_SET" == "office" ]; then
    UNKNOWN_OPT="0"
    echo "Downloading $DOWNLOAD_SET ..."
    progdownload "$WORKINGDIR/support/office.txt" "office"
  fi
  if [ "$DOWNLOAD_SET" == "clear_logs" ]; then
    UNKNOWN_OPT="0"
    if [ -n != "`ls $WORKINGDIR/logs/badfiles/`" ] ; then
      rm -f $WORKINGDIR/logs/badfiles/* && echo "files cleared"
    else echo "no files to clear"
    fi
    if [ -f $WORKINGDIR/logs/failed.txt ] ; then
      NOW=`date`
      mv $WORKINGDIR/logs/failed.txt "$WORKINGDIR/logs/failed: $NOW.txt"
      echo "failed.txt archived and cleared."
    else echo "no logs to clear"
    fi
  fi
  if [ "$DOWNLOAD_SET" == "configure" ]; then
    UNKNOWN_OPT="0"
    echo "Please enter the path to the folder you would like your new downloads to be dropped off:"
    read DOWNLOAD_DIRECTORY
    export DOWNLOAD_DIRECTORY
  fi
  if [ "$DOWNLOAD_SET" == "exit" ]; then
    UNKNOWN_OPT="0"
    echo "Goodbye!"
    DOWNLOAD_SET="exit"
  fi
  if [ "$UNKNOWN_OPT" == "1" ] ; then
  echo "I beg your pardon?"
  fi
done
