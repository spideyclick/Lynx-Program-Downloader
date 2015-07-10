#!/bin/bash

###CHANGELOG:
# Where am I now?  Debugging all of the crazy changes I just made!
# 2015-04-08 Added dependency check, ssh check, started work on $1, $2 options, relative directories, centralized logfile.
# 2015-04-14 Integrating a working option checker
# 2015-04-22 Options are represented both as switches and menu options
# 2015-05-01  Fixed echo's and logging

###UPCOMING FEATURES (TODO):
# Possibly use telnet?
# More supported download websites (smart URL selection, WGET switch, etc.)
# File compare (update only): If the name is the same, don't download it.  If the size is the same after downloading, delete the new file.
# Report:  x mbytes downloaded, x programs updated, x programs not updated, x programs error.
# More detailed logs.  What did $DOWNLOADER download?  When did it start and stop?  Centralize this stuff.
# Okay, this is cool.  We can report number of files downloaded with x extension!
# echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
# add GUI check (Then a QT or Zenity GUI), package as DEB!
# Add a config option:  Would you like download names to be the last time downloaded or the last time updated?
# Optimize and standardize the code to what I now know to be right!
# The oldfile thing is going to require a small database containing the most recent download, download name, and hash.
# Perhaps this file should be the download configuration anyway, where the URL's go.
# "download name" "download URL" "alternate download URL" "newest version file location" "hash"
# Probably requires an SQLite Database (again)

# EXTRA NOTES
# Cool thing:  unset DOWNLOADER works, but unset $DOWNLOADER does not!

# Immediate TODO:
# Merge downloader and pdu
#   Get -s option working
#   Get rid of exports
#   Change empty comparisons
#   Kill last absolute paths
#   Make sure other options work
#   Get the following bug:
#   bash: [: ==: unary operator expected
# Implement the new config file system.
#   Need to create a new switch for db:  -c . Will find all programs matchine CATEGORY and return an array variable with all program names for downloading.
#     The problem I am having with this is that array variables within array variables get mashed together; it's not like a python dictionary where you can request the third array out of your arrays; it stacks all the arrays into one single, serial array.
#     I may have a solution:  Read the whole text file, filtered with a grep of what groups you are looking for (for CAT in CATEGORIES, do grep file for CAT) into an array called current downloads or something like that.  Then, furher split it into more arrays--for download in curr_downloads, do download download[4].
#     IFS=$'\n' read -d '' -r -a lines < support/Progdownloads.csv
#     The thing is we are replacing the original search function.  Before, we could only search for the beginning of an entry.  Now we will be able to search for any field and replace it.
#     As a check, I'd like to see if we can match a result to the column it shows up in.  If we specify which column to find it in, we discard all results in lines found elsewhere.
#   cat support/Programs\ for\ monthly\ update.csv | grep -i ">antivirus>" > support/downloading.txt
#   SELECT $DOWNLOAD_SET
#   for line in database download if $CATEGORY is in $DOWNLOAD_SET
#   SET=(`cat support/Programs\ for\ monthly\ update.csv | grep -iE ">utilities>|>office>" | awk 'BEGIN { FS=">" } { print $1 }'`)
#   Upon a new download, read last download date.  If date != today, update date and download.
#   Try request URL 1 and download
#   if tmp is empty, try request URL 2 and download
#   if tmp is empty, return error
#   md5sum new download
#   read md5sum of old download
#   if old download does not exist, do not match md5sum but mv new download to this month's download set.  Write "new" to the report.  Modify download date, filename and new md5sum in report.
#   if md5sums match, rm new download, update download date of old and move to this month's download set.  Write "not updated" to the report.
#   if md5sums do not match, mv new download to this month's download set.  Write "updated" to the report.  Modify download date, file name and new md5sum in report.
#   At end, display report.

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
LOGFILE="$WORKINGDIR/support/pdu.log"
CONFIG_FILE="$WORKINGDIR/support/Programs for monthly update.csv"

printlog () {
  echo $1
  echo $1 >> $LOGFILE
  if [ $2 == "failed" ] ; then
    echo $1 >> "$WORKINGDIR/logs/failed.txt"
  fi
  }

db () {
# $CONFIG_FILE is assumed to exist!
# This function searches for the beginnig of a line (program name, must be first!) then replaces the specified field of the line it is found on.
# This function alone is the reason that 64 MUST be placed BEFORE the program title in the config file.
  if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-help" ] ; then
    echo "db:  a function for requesting or modifying information from csv files."
    echo "Usage: filemod PROGRAM_NAME FIELD_NUMBER VALUE(opt)"
    echo "filemod PuTTY 1 "PuTTY" #This renames an entry."
    echo "filemod PuTTY 2 	#This requests the category of an entry."
    echo "filemod PuTTY 0 	#This requests the line number of an entry."
    return 0
  fi
  echo "searching $CONFIG_FILE for $1..."
  CURLINE=$(cat "$CONFIG_FILE" | grep -i -n "^$1" | sed 0,/\:/{s/\:/\>/})
  if [ -z "$CURLINE" ] ; then
    echo "HELP!  Entry not found in config!"
  else echo "entry found."
  fi
  IFS='>' read -a CURLINE <<< "$CURLINE"
  echo "${CURLINE[*]}"
  if [ -z != $3 ] ; then
    CURLINE[$2]=$3
    echo "new value: ${CURLINE[$2]}"
    NEWLINE="${CURLINE[1]}>${CURLINE[2]}>${CURLINE[3]}>${CURLINE[4]}>${CURLINE[5]}>${CURLINE[6]}"
#     NEWLINE="foo"
    sed -i ${CURLINE[0]}s~.*~"$NEWLINE"~ "$CONFIG_FILE"
  elif [ -z != $2 ] ; then
    echo "${CURLINE[$2]}"
  fi
  }

###OPTIONS
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
    if [ $2 == "unsorted" ] ; then
      wget $URL && echo "Wget download complete!"
    else
      lynx -cmd_script="$WORKINGDIR/support/mgcmd.txt" --accept-all-cookies $URL && echo "lynx complete!"
    fi
    FILE=`(ls | head -n 1)` && echo $FILE
    EXT=`echo -n $FILE | tail -c 3` && echo $EXT
    BAD=`cat "$WORKINGDIR/support/whiteexts.txt" | grep -v "#" | grep -cim1 "$EXT"` && echo $BAD
    OLDFILE=`ls "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$2/" | grep -i "${FILE%%.*}.${FILE#*.}"` && echo $OLDFILE
    if [ -z "$FILE" ] ; then
      printlog "Download incomplete: $URL" "failed"
    else
      until [ -z "$FILE" ] ; do
	if [ $BAD == "0" ] ; then
	  printlog "Download $FILE is of unknown type. $URL failed"
	  mv "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/$FILE"
	elif [ "$OLDFILE" != "" ] ; then
	  echo "Oldfile exists!"
	  if [ `md5sum $FILE` != `md5sum $OLDFILE` ] ; then
	    echo "This is a new version!"
	    mv "$FILE" "$DOWNLOAD_DIRECTORY/`date +%Y-%m`/$2/${FILE%%.*}($DOWNLOADER-$NOW).${FILE#*.}"
	  else echo "This download is the same version as the last download."
	  fi
	else echo "new file downloaded."
	  mv "$FILE" "$DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/$DOWNLOAD_SET/$FILE"
	fi
	FILE=`(ls | head -n 1)`
      done
    fi
    cd "$WORKINGDIR" && pwd
  done
  }

urlget() {
  TMP=$(cat $CONFIG_FILE | grep -i "^$1")
  IFS='>' read -a CURPROG <<< "$TMP"
  printlog "${CURPROG[$0]} selected..."
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
  echo "all majorgeeks wgets antivirus creative utilities office clear_logs configure exit"
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
  if [ "$DOWNLOAD_SET" == "wgets" ]; then
    UNKNOWN_OPT="0"
    echo "Downloading $DOWNLOAD_SET ..."
    progdownload "$WORKINGDIR/support/wgetadrs.txt" "unsorted"
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
