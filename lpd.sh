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
mkdir $DOWNLOAD_DIRECTORY
mkdir $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE
LOGFILE="$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress.log"
touch $LOGFILE

printlog () {
  echo $1
  if [ "$2" == "failed" ] ; then
    echo "FAIL:  $1" >> $LOGFILE
  else
    echo $1 >> $LOGFILE
  fi
  }

###OPTIONS PROCESSING
SKIP_ARG="0"
for ARG ; do
  if [ -n != "$ARG" ] ; then
    UNKNOWN_OPT="1"
    if [ "$SKIP_ARG" == "1" ] ; then
      SKIP_ARG="0"
      UNKNOWN_OPT="0"
    fi
    if [ "$ARG" == "-h" ] || [ "$ARG" == "--help" ] ; then
      echo "Usage: pdu.sh -i [USER'S INITIALS]... -s [DOWNLOAD SET]... -c -h"
      echo "  -h, --help 			prints this help message"
      echo "  -i, --initials       Specifies initials to be appended to file names"
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
      UNKNOWN_OPT="0"
      printlog "renaming download_progress.log to download_progress_`date`.log"
      mv $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress.log "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress_`date`.log"
      printlog "logs cleared:  renamed download_progress.log to download_progress_`date`.log"
      if [ -n != "`ls $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/`" ] ; then
        rm -f $WORKINGDIR/logs/badfiles/* && printlog "files cleared"
      else printlog "no files to clear"
      fi
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

###FUNCTIONS
pckmgrchk () {
  which rpm
  if [ "$?" == "0" ] ; then
    PKGMAN="rpm"
    printlog "Package Manager: $PKGMAN"
  fi
  which apt
  if [ "$?" == "0" ] ; then
    PKGMAN="apt"
    printlog "Package Manager: $PKGMAN"
  fi
  if [ -z "$PKGMAN" ] ; then
    printlog "Package manager not recognized!  Please make sure rpm or apt are installed and working!" && return 1
  fi
  }


depcheck () {
  which "$1" >> /dev/null
  if [ "$?" != "0" ] ; then
    printlog "This program requires $1 to be installed in order to run properly.  You can install it by typing:"
    if [ "$PKGMAN" == "apt" ] ; then
      printlog "sudo apt-get install $1"
      INSACTN="apt-get"
    elif [ "$PKGMAN" == "rpm" ] ; then
      printlog "yum install $1"
      INSACTN="yum"
      
    else printlog "Package manager not recognized!  Please make sure rpm or apt are installed and working!" && return 1
    fi
    printlog "Or we can try to install it right now.  Would you like to? (Y/N)"
    UINPUT=0
    read UINPUT # grab first letter of input, upper or lower it, and check for THAT input.  Shorter.
    until [ $UINPUT == "exit" ] ; do
      if [ $UINPUT == "Y" ] || [ $UINPUT == "y" ] || [ $UINPUT == "yes" ] || [ $UINPUT == "Yes" ] || [ $UINPUT == "YES" ] ; then
        printlog "Installing $1..."
        sudo $INSACTN install $1
	UINPUT="exit"
      elif [ $UINPUT == "N" ] || [ $UINPUT == "n" ] || [ $UINPUT == "no" ] || [ $UINPUT == "No" ] || [ $UINPUT == "NO" ] ; then
	    printlog "Package install cancelled." && return 0
      else echo "I beg your pardon?"
      fi
    done
  else printlog "Dependency check of $1 success"
  fi }

progupdatechk () {
  if [ -f "$2" ] ; then
    printlog "File already in download directory!  Deleting new file and skipping..."
    rm -f $1
  else
    printlog "Moving $1 to $2..."
    mv "$1" "$2"
  fi
  }

progdownload () {
  mkdir "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$2"
  NOW=$(date +"%Y_%m_%d") && printlog "$DOWNLOAD_SET started at $NOW"
  MYNUM="0"
  until [ "$URL" == "exit" ] ; do
    echo "" >> $LOGFILE
    MYNUM=$((MYNUM + 1))
    URL="$(sed ''$MYNUM'q;d' $1)" && printlog "$MYNUM) downloading $URL"
    mkdir "$WORKINGDIR/tmp"
    cd "$WORKINGDIR/tmp"
    lynx -cmd_script="$WORKINGDIR/support/mgcmd.txt" --accept-all-cookies $URL
    FILE=`(ls | head -n 1)`
    if [ -z "$FILE" ] ; then
      printlog "Download incomplete: $URL" "failed"
    else
      EXT=`echo -n $FILE | tail -c 3`
      BAD=`cat "$WORKINGDIR/support/whiteexts.txt" | grep -v "#" | grep -cim1 "$EXT"`
      until [ -z "$FILE" ] ; do
        if [ $BAD == "0" ] ; then
          mv "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/$FILE"
          printlog "Download $FILE is of unknown type. $URL" "failed"
        else
          if [ -z $DOWNLOADER ] ; then
            progupdatechk "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$DOWNLOAD_SET/$FILE"
          else
            progupdatechk "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$DOWNLOAD_SET/${FILE%%.*}($DOWNLOADER).${FILE#*.}"
          fi
          printlog "Download success of $FILE from $URL"
        fi
        FILE=`(ls | head -n 1)`
      done
    fi
    cd "$WORKINGDIR"
  done
  }

###PROGRAM START
cd $WORKINGDIR
echo "" >> $LOGFILE
printlog "lpd started at `date`"

###DEPENDENCY CHECK
pckmgrchk
depcheck wget
depcheck lynx

###MENU
mkdir "$DOWNLOAD_DIRECTORY/`date +%Y-%m`"
mkdir "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles"
if [ -z $DOWNLOAD_SET ] ; then
  until [ "$DOWNLOAD_SET" == "exit" ] ; do
    UNKNOWN_OPT="1"
    echo "Which batch would you like to download?"
    echo "all antivirus creative utilities office clear_logs configure exit"
  #   DOWNLOAD_SELECTION="All Majorgeeks Wgets Antivirus Creative Utilities Office Clear_logs Configure Exit"
  #   select opt in $DOWNLOAD_SELECTION; do
  #     DOWNLOAD_SET="$opt"
  #   done
    read DOWNLOAD_SET
    if [ "$DOWNLOAD_SET" == "all" ] ; then
      UNKNOWN_OPT="0"
      printlog "Downloading $DOWNLOAD_SET ..."
      progdownload "$WORKINGDIR/wgetadrs.txt" "unsorted"
      progdownload "$WORKINGDIR/support/antivirus.txt" "antivirus"
      progdownload "$WORKINGDIR/support/creative.txt" "creative"
      progdownload "$WORKINGDIR/support/utilities.txt" "utilities"
      progdownload "$WORKINGDIR/support/office.txt" "office"
    fi
    if [ "$DOWNLOAD_SET" == "antivirus" ]; then
      UNKNOWN_OPT="0"
      printlog "Downloading $DOWNLOAD_SET ..."
      progdownload "$WORKINGDIR/support/antivirus.txt" "antivirus"
    fi
    if [ "$DOWNLOAD_SET" == "creative" ]; then
      UNKNOWN_OPT="0"
      printlog "Downloading $DOWNLOAD_SET ..."
      progdownload "$WORKINGDIR/support/creative.txt" "creative"
    fi
    if [ "$DOWNLOAD_SET" == "utilities" ]; then
      UNKNOWN_OPT="0"
      printlog "Downloading $DOWNLOAD_SET ..."
      progdownload "$WORKINGDIR/support/utilities.txt" "utilities"
    fi
    if [ "$DOWNLOAD_SET" == "office" ]; then
      UNKNOWN_OPT="0"
      printlog "Downloading $DOWNLOAD_SET ..."
      progdownload "$WORKINGDIR/support/office.txt" "office"
    fi
    if [ "$DOWNLOAD_SET" == "clear_logs" ]; then
      UNKNOWN_OPT="0"
      printlog "renaming download_progress.log to download_progress_`date`.log"
      mv $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress.log "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress_`date`.log"
      printlog "logs cleared:  renamed download_progress.log to download_progress_`date`.log"
      if [ -n != "`ls $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/`" ] ; then
        rm -f $WORKINGDIR/logs/badfiles/* && printlog "files cleared"
      else printlog "no files to clear"
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
      printlog "Goodbye!"
      DOWNLOAD_SET="exit"
    fi
    if [ "$UNKNOWN_OPT" == "1" ] ; then
    echo "I beg your pardon?"
    fi
  done
else
  printlog "Downloading $DOWNLOAD_SET ..."
  progdownload "$WORKINGDIR/support/$DOWNLOAD_SET.txt" "$DOWNLOAD_SET"
fi
