#!/usr/bin/env bash

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
CONFIG_FILE="$WORKINGDIR/support/program_list.csv"
DOWNLOAD_DIRECTORY="$WORKINGDIR/downloads"
mkdir $DOWNLOAD_DIRECTORY
mkdir $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE
LOGFILE="$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress.log"
touch $LOGFILE

printlog () {
  if [ "$2" == "failed" ] ; then
    echo "FAIL:  $1" >> $LOGFILE
    echo "FAIL:  $1"
  else
    echo $1 >> $LOGFILE
    echo $1
  fi
  }

###OPTIONS PROCESSING
while getopts hrtc:i:s: OPT ; do
  case $OPT in
		h)
			echo "Usage: pdu.sh -hr -i [USER'S INITIALS]... -s [DOWNLOAD SET] -c [DOWNLOAD DIRECTORY]"
			echo "  -h		prints this help message and exit"
			echo "  -i		Specify initials to be appended to file names"
			echo "  -s		Choose from a predefined set of downloads"
			echo "  -c		Configure download directory to place new downloads in"
			echo "  -r		resets all logs"
			echo ""
			echo "Welcome to the Program Downloader Utility (PDU).  This program was created to automatically download programs from the internet using the terminal-based Lynx web browser."
			echo "Configuration files can be found in the support/ directory.  Every URL given in the categories will be downloaded into a matching subfolder.  At this time, only websites from majorgeeks.com are supported, and you will want to put the download page in line, NOT the general information page.  This allows you to choose which mirror you'd like to download.  For all other direct downloads, you can put them in 'unsorted', and they will be downloaded via wget."
			exit 0
		;;
		r)
			printlog "renaming download_progress.log to download_progress_`date`.log"
			mv $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress.log "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/download_progress_`date`.log"
			printlog "logs cleared:  renamed download_progress.log to download_progress_`date`.log"
			if [ -n != "`ls $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/`" ] ; then
			rm -f $WORKINGDIR/logs/badfiles/* && printlog "files cleared"
			else printlog "no files to clear"
			fi
		;;
		t)
			printlog "Test mode: relax and enjoy."
			TEST="1"
		;;
		c)
			DOWNLOAD_DIRECTORY="$OPTARG"
			printlog "Downloading to $DOWNLOAD_DIRECTORY."
		;;
		i)
			DOWNLOADER="$OPTARG."
			printlog "$DOWNLOADER will be appended to filenames."
		;;
		s)
			DOWNLOAD_SET="$OPTARG"
			printlog "Downloading $2..."
		;;
  esac
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
    printlog "Package manager not recognized!  Please make sure rpm or apt are installed and working!" "failed" && return 1
  fi
  }


depcheck () {
  which "$1" >> /dev/null
  if [ "$?" != "0" ] ; then
    printlog "This program requires $1 to be installed in order to run properly.  You can install it by typing:" "failed"
    if [ "$PKGMAN" == "apt" ] ; then
      printlog "sudo apt-get install $1"
      INSACTN="apt-get"
    elif [ "$PKGMAN" == "rpm" ] ; then
      printlog "yum install $1"
      INSACTN="yum"
    else printlog "Package manager not recognized!  Please make sure rpm or apt are installed and working!" "failed" && return 1
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
	    printlog "Package install cancelled." "failed" && return 0
      else echo "I beg your pardon?"
      fi
    done
  else printlog "Dependency check of $1 success"
  fi }

db () {
# $CONFIG_FILE is assumed to exist!
# This function searches for the beginnig of a line (program name, must be first!) then replaces the specified field of the line it is found on.
# This function alone is the reason that 64 MUST be placed BEFORE the program title in the config file.
  if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-help" ] ; then
    echo "db:  a function for requesting or modifying information from csv files."
    echo "Usage: filemod PROGRAM_NAME FIELD_NUMBER VALUE(opt)"
    echo "filemod (program name) (column number) (new value)"
    echo "filemod PuTTY 1 PUT #This renames the first column (name) of PuTTY to PUT."
    echo "filemod PuTTY 2 #This requests the category of an entry."
    echo "filemod PuTTY 0 #This requests the line number of an entry."
    return 0
  fi
#   "searching $CONFIG_FILE for $1..."
  CURLINE=$(cat "$CONFIG_FILE" | grep -i -n "^$1" | sed 0,/\:/{s/\:/\>/})
  if [ -z "$CURLINE" ] ; then printlog "Entry not found in config!" "failed" ; fi
  IFS='>' read -a CURLINE <<< "$CURLINE"
  if [ -z != $3 ] ; then
    CURLINE[$2]=$3
    printlog "new value: ${CURLINE[$2]}"
    NEWLINE="${CURLINE[1]}>${CURLINE[2]}>${CURLINE[3]}>${CURLINE[4]}>${CURLINE[5]}>${CURLINE[6]}"
    sed -i ${CURLINE[0]}s~.*~"$NEWLINE"~ "$CONFIG_FILE"
  elif [ -z != $2 ] ; then
    echo "${CURLINE[$2]}"
  fi
  }

# db PuTTY 3 utilities

# if [ "$TEST" == "1" ] ; then exit 0 ; fi

progupdatechk () {
  if [ -f "$2" ] ; then
    printlog "File already in download directory!  Deleting new file and skipping..."
    rm -f $1
  else
    printlog "Moving $1 to $2..."
    mv "$1" "$2"
    db $PROGRAM_NAME 2 $NOW
  fi
  }

progdownload () {
  printlog "Downloading $DOWNLOAD_SET ..."
  mkdir "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$DOWNLOAD_SET"
  NOW=$(date +"%Y_%m_%d") && printlog "$DOWNLOAD_SET started on $NOW"
  MYNUM="0"
  DOWNLOAD_LIST=`cat $CONFIG_FILE | grep ">$DOWNLOAD_SET>" | cut -d \> -f 1`
  for PROGRAM_NAME in $DOWNLOAD_LIST ; do
    echo "" >> $LOGFILE
    MYNUM=$((MYNUM + 1))
    URL=`db $PROGRAM_NAME 4` && printlog "$MYNUM) downloading $URL"
    mkdir "$WORKINGDIR/tmp" 2> /dev/null 
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
          progupdatechk "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/$FILE"
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
    echo "all antivirus creative utilities office clear_logs configure help exit"
  #   DOWNLOAD_SELECTION="All Majorgeeks Wgets Antivirus Creative Utilities Office Clear_logs Configure Exit"
  #   select opt in $DOWNLOAD_SELECTION; do
  #     DOWNLOAD_SET="$opt"
  #   done
    read DOWNLOAD_SET
    if [ "$DOWNLOAD_SET" == "all" ] ; then
      UNKNOWN_OPT="0"
      DOWNLOAD_SET="antivirus"
      progdownload
      DOWNLOAD_SET="creative"
      progdownload
      DOWNLOAD_SET="utilities"
      progdownload
      DOWNLOAD_SET="office"
      progdownload
    fi
    if [ "$DOWNLOAD_SET" == "antivirus" ] || [ "$DOWNLOAD_SET" == "creative" ] || [ "$DOWNLOAD_SET" == "utilities" ] || [ "$DOWNLOAD_SET" == "office" ] ; then
      UNKNOWN_OPT="0"
      progdownload
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
    fi
    if [ "$DOWNLOAD_SET" == "help" ]; then
      UNKNOWN_OPT="0"
			echo "Usage: pdu.sh -hr -i [USER'S INITIALS]... -s [DOWNLOAD SET] -c [DOWNLOAD DIRECTORY]"
			echo "  -h		prints this help message and exit"
			echo "  -i		Specify initials to be appended to file names"
			echo "  -s		Choose from a predefined set of downloads"
			echo "  -c		Configure download directory to place new downloads in"
			echo "  -r		resets all logs"
			echo ""
			echo "Welcome to the Program Downloader Utility (PDU).  This program was created to automatically download programs from the internet using the terminal-based Lynx web browser."
			echo "Configuration files can be found in the support/ directory.  Every URL given in the categories will be downloaded into a matching subfolder.  At this time, only websites from majorgeeks.com are supported, and you will want to put the download page in line, NOT the general information page.  This allows you to choose which mirror you'd like to download.  For all other direct downloads, you can put them in 'unsorted', and they will be downloaded via wget."
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
  progdownload "$WORKINGDIR/support/$DOWNLOAD_SET.txt" "$DOWNLOAD_SET"
fi
