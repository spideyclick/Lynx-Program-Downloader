#!/usr/bin/env bash
# Lynx Program Downloader 1.0
# Licenced under the GNU General Public License, Version 2
# Refer to readme.md for details on what this program is and how to use it.
# Authored by Zachary (spideyclick) Hubbell. Code maintained at GitHub (send bug reports here!):
# https://github.com/spideyclick/Lynx-Program-Downloader

###CLEAR VARIABLES
DOWNLOAD_SET=""
DOWNLOADER=""
PKGMAN=""
DOWNLOAD_SELECTION=""
UNKNOWN_OPT=""
CATEGORY=""
TEST=0

# !!!TEST copy this line wherever you need the script to stop in a test
if [ ${TEST} -eq 1 ] ; then exit 0 ; fi

###SET VARIABLES
WORKINGDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DOWNLOAD_DATE="$(date +%Y-%m)"

###CONFIGURATION
FORCE_DOWNLOADS="off" # set to "on" to re-download programs already downloaded this month, or set to "off" to skip them.
CONFIG_FILE="${WORKINGDIR}/support/program_list.csv" # path to your CSV file, see support/program_list.csv for an example.
DOWNLOAD_DIRECTORY="${WORKINGDIR}/downloads" # default path to your downlad directory of choice.

###MAKE DIRECTORIES
mkdir "${DOWNLOAD_DIRECTORY}" 2> /dev/null
mkdir "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}" 2> /dev/null
LOGFILE="${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/download_progress.log"
touch "${LOGFILE}"

###PRE-OPTION FUNCTIONS
printlog () {
  if [ "x${2}" == "xfailed" ] ; then
    tee -a "${LOGFILE}" <<< "FAIL: ${1}"
  else
    tee -a "${LOGFILE}" <<< "${1}"
  fi
  }

categoryget () {
  DOWNLOAD_LIST=$(cat support/program_list.csv | cut -d \> -f 2)
  OLDITEM=""
  NEWITEM=""
  for SET in ${DOWNLOAD_LIST} ; do
    if [ "$OLDITEM" != "$SET" ] ; then
      OLDITEM="${SET}"
      NEWITEM="${NEWITEM} ${SET}"
    fi
  done
  echo "${NEWITEM}"
  }
CATEGORIES="$(categoryget)"

downloadsetget () {
  NEWITEM=""
  for QUERY in ${1} ; do
    for CATEGORY in ${CATEGORIES} ; do
      FINDINGS=$(grep "${QUERY}" <<< "${CATEGORY}")
      if [ "x${FINDINGS}" != "x" ] ; then NEWITEM="${NEWITEM} ${FINDINGS}" ; fi
    done
  done
  echo "${NEWITEM}"
  }

###OPTIONS PROCESSING
while getopts hrtfc:i:s: OPT ; do
  case "${OPT}" in
    h)
      echo "Usage: bash $0 [-hrf] [-i USER'S INITIALS] [-s \"CATGORIES CATEGORIES\"] [-c DOWNLOAD_DIRECTORY]"
      echo "  -h    prints this help message and exit"
      echo "  -r    resets all logs, remove bad files"
      echo "  -f    force downloading of programs already downloaded this month"
      echo "  -i    Specify initials to be appended to file names"
      echo "  -s    Choose a set of downloads according to category in the CSV file"
      echo "  -c    Configure download directory to place new downloads"
      echo ""
      echo "Welcome to Lynx Program Downloader. This program was created to automatically download files from the internet using the terminal-based Lynx web browser."
      echo "Programs are downloaded in batches designated by category in the database (the CSV file in the support directory). There, you can set different mirrors, names and categories for programs, as well as see their download history, filename and MD5 hash. URLs that match a given pattern will be downloaded with an existing download script (also found in the support directory), if available. Otherwise, they will be downloaded via wget."
      echo "If you would like to save where the downloads go by default, you can change the variable \${DOWNLOAD_DIRECTORY} in the CONFIG section at the beginning of the script."
      echo "If you would like to save the default downloader initials, put something inside the \${DOWNLOADER} variable at the beginning of the script."
      echo "If you would like to force downloads whether done this month or not, change the \${FORCE_DOWNLOADS} variable at the beginning of the script to 'on'."
      exit 0
    ;;
    r)
      mv "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/download_progress.log" "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/download_progress_$(date).log"
      printlog "logs cleared:  renamed download_progress.log to download_progress_$(date).log"
      if [ "x$(ls $DOWNLOAD_DIRECTORY/$DOWNLOAD_DATE/badfiles/)" != "x" ] ; then
      rm -f ${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/badfiles/* && printlog "bad files cleared"
      else printlog "no bad files to clear"
      fi
    ;;
    t)
      printlog "Test mode: relax and enjoy."
      TEST=1
    ;;
    c)
      DOWNLOAD_DIRECTORY="${OPTARG}"
      printlog "Downloads will go to ${DOWNLOAD_DIRECTORY}."
    ;;
    i)
      DOWNLOADER="${OPTARG}"
      printlog "${DOWNLOADER} will be appended to filenames."
    ;;
    s)
      DOWNLOAD_SELECTION="${OPTARG}"
      if [ "x${DOWNLOAD_SELECTION}" == "xall" ] ; then
        DOWNLOAD_SET="${CATEGORIES}"
      else
        DOWNLOAD_SET="$(downloadsetget ${DOWNLOAD_SELECTION})"
        if [ -z "${DOWNLOAD_SET}" ] ; then
          printlog "${DOWNLOAD_SELECTION} not found in available categories for download: ${CATEGORIES}" "failed"
          exit 1
        fi
      fi
    ;;
    f)
      FORCE_DOWNLOADS="on"
      printlog "Toggle force programs downloaded this month to be downloaded again: ${FORCE_DOWNLOADS}"
    ;;
  esac
done

###FUNCTIONS
pckmgrchk () {
  which rpm >> /dev/null
  if [ $? -eq 0 ] ; then
    PKGMAN="rpm"
    printlog "Package Manager: ${PKGMAN}"
  fi
  which apt >> /dev/null
  if [ $? -eq 0 ] ; then
    PKGMAN="apt"
    printlog "Package Manager: ${PKGMAN}"
  fi
  if [ -z "${PKGMAN}" ] ; then
    printlog "Package manager not recognized!  Please make sure rpm or apt are installed and working!" "failed" && exit 1
  fi
  }

depcheck () {
  which "${1}" >> /dev/null
  if [ ${?} -ne 0 ] ; then
    printlog "This program requires ${1} to be installed in order to run properly. You can install it by typing:" "failed"
    if [ "x${PKGMAN}" == "xapt" ] ; then
      printlog "sudo apt-get install ${1}"
      INSACTN="apt-get"
    elif [ "x${PKGMAN}" == "xrpm" ] ; then
      printlog "sudo yum install ${1}"
      INSACTN="yum"
    else printlog "Package manager not recognized! Please make sure rpm or apt are installed and working!" "failed" && exit 1
    fi
    printlog "Or we can try to install it right now. Would you like to? (Y/N)"
    UINPUT=0
    until [ "x${UINPUT}" == "xexit" ] ; do
      read UINPUT
      if [ "x${UINPUT}" == "xY" ] || [ "x${UINPUT}" == "xy" ] || [ "x${UINPUT}" == "xyes" ] || [ "x${UINPUT}" == "xYes" ] || [ "x${UINPUT}" == "xYES" ] ; then
        printlog "Installing ${1}..."
        sudo ${INSACTN} install ${1}
        UINPUT="exit"
      elif [ "x${UINPUT}" == "xN" ] || [ "x${UINPUT}" == "xn" ] || [ "x${UINPUT}" == "xno" ] || [ "x${UINPUT}" == "xNo" ] || [ "x${UINPUT}" == "xNO" ] ; then
        printlog "Package install cancelled." "failed" && return 0
      else echo "I beg your pardon?"
      fi
    done
  else printlog "Dependency check of ${1} success"
  fi
  }

db () {
# This function alone is the reason that 64 MUST be placed BEFORE the program title in the config file.
# Blank fields will be replaced with a '-'. This makes blank columns stay in place.
  if [ "x${1}" == "x-h" ] || [ "x${1}" == "x--help" ] || [ "x${1}" == "x-help" ] ; then
    echo "db:  a function for requesting or modifying information from csv files. Assumes \$CONFIG_FILE Exists."
    echo "Usage: filemod PROGRAM_NAME FIELD_NUMBER VALUE(opt)"
    echo "filemod (program name) (column number) (new value)"
    echo "filemod PuTTY 1 PUT #This renames the first column (name) of PuTTY to PUT."
    echo "filemod PuTTY 2 #This requests the category of an entry."
    echo "filemod PuTTY 0 #This requests the line number of an entry."
    return 0
  fi
  CURLINE=$(cat "${CONFIG_FILE}" | grep -i -n "^${1}" | sed 0,/\:/{s/\:/\>/} | sed "s/>>/>->/g")
  if [ -z "${CURLINE}" ] ; then printlog "Entry not found in config!" "failed" ; fi
  IFS='>' read -a CURLINE <<< "${CURLINE}"
  if [ -z != ${3} ] ; then
    CURLINE[${2}]=${3}
    printlog "new value: ${CURLINE[${2}]}"
    NEWLINE=""
    COL_NUM=0
    for column in ${CURLINE[@]} ; do
      COL_NUM=$((COL_NUM + 1))
      NEWLINE="$NEWLINE${CURLINE[$COL_NUM]}>"
    done
    NEWLINE="${NEWLINE%?}"
    sed -i ${CURLINE[0]}s~.*~"${NEWLINE}"~ "${CONFIG_FILE}"
  elif [ -z != ${2} ] ; then
    if [ "x${CURLINE[${2}]}" == "x-" ] || [ "x${CURLINE[${2}]}" == "x" ] ; then echo "field empty"
    else echo "${CURLINE[${2}]}"
    fi
  fi
  }

progdownload () {
  printlog "attmpting download from ${URL}"
  if echo "${URL}" | grep -q "http://www.majorgeeks.com/" ; then
    lynx -cmd_script="${WORKINGDIR}/support/mgcmd.txt" --accept-all-cookies ${URL}
  elif echo "${URL}" | grep -q "http://filehippo.com/download_" ; then
    lynx -cmd_script="${WORKINGDIR}/support/fhcmd.txt" --accept-all-cookies ${URL}
  elif echo "${URL}" | grep -q "http://sourceforge.net" ; then
    lynx -cmd_script="${WORKINGDIR}/support/sfcmd.txt" --accept-all-cookies ${URL}
  else wget ${URL}
  fi
  }

progupdatechk () {
  OLD_FILE_NAME=$(db ${PROGRAM_NAME} 4)
  MD5_OLD=$(db ${PROGRAM_NAME} 5)
  IFS=' ' read -a MD5_NEW <<< $(md5sum ${FILE})
  MD5_NEW=${MD5_NEW[0]}
  if [ "x${MD5_NEW}" == "x${MD5_OLD}" ] ; then
    printlog "File has not changed since last download.  Deleting and moving old file to new download directory..."
    rm -f "${FILE}"
    mv "${DOWNLOAD_DIRECTORY}/${LAST_DOWNLOAD_MONTH}/${CATEGORY}/${OLD_FILE_NAME}" "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/${CATEGORY}/${OLD_FILE_NAME}"
    db "${PROGRAM_NAME}" 3 $(date +%Y-%m-%d)
  else
    printlog "File is new! Moving to download folder..."
    if [ -z != ${DOWNLOADER} ] ; then NEW_FILE="${FILE%%.*}(${DOWNLOADER}).${FILE#*.}" ; else NEW_FILE="${FILE}" ; fi
    mv "${FILE}" "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/${CATEGORY}/${NEW_FILE}"
    db "${PROGRAM_NAME}" 3 $(date +%Y-%m-%d)
    db "${PROGRAM_NAME}" 4 "${NEW_FILE}"
    db "${PROGRAM_NAME}" 5 "${MD5_NEW}"
    printlog "SUCCESS: ${FILE} from ${URL}"
  fi
  }

progprocess () {
  PROGNUM=0
  for CATEGORY in ${DOWNLOAD_SET} ; do
    mkdir "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/${CATEGORY}" 2> /dev/null
    NOW=$(date +"%Y_%m_%d") && printlog "" && printlog "${CATEGORY} started on ${NOW}"
    DOWNLOAD_LIST=$(cat ${CONFIG_FILE} | grep ">${CATEGORY}>" | cut -d \> -f 1)
    for PROGRAM_NAME in ${DOWNLOAD_LIST} ; do
      printlog ""
      IFS='-' read -a LAST_DOWNLOAD_MONTH <<< $(db ${PROGRAM_NAME} 3) ; LAST_DOWNLOAD_MONTH="${LAST_DOWNLOAD_MONTH[0]}-${LAST_DOWNLOAD_MONTH[1]}"
      if [[ "x${FORCE_DOWNLOADS}" == "xoff" && ( "x${LAST_DOWNLOAD_MONTH}" == "x${DOWNLOAD_DATE}" ) ]] ; then
        printlog "${PROGRAM_NAME} has already been downloaded this month. Skipping..."
      else
        PROGNUM=$((PROGNUM + 1))
        printlog "${PROGNUM}) downloading ${PROGRAM_NAME}"
        mkdir "${WORKINGDIR}/tmp" 2> /dev/null
        cd "${WORKINGDIR}/tmp"
        TRY=1
        URLNUM=5
        while [ ${TRY} -eq 1 ] ; do
          URLNUM=$((URLNUM + 1))
          URL=$(db ${PROGRAM_NAME} ${URLNUM})
          if [ "x${URL}" == "xfield empty" ] ; then
            TRY=0
            printlog "Out of mirrors! No suitable download found for ${PROGRAM_NAME}..." "failed"
          else
            progdownload
            FILE=$(ls | head -n 1)
            if [ -z "${FILE}" ] ; then
              printlog "Download incomplete: ${URL}" "failed"
            else
              EXT=$(echo -n ${FILE} | tail -c 3)
              BAD=$(cat "${WORKINGDIR}/support/whiteexts.txt" | grep -v "#" | grep -cim1 "${EXT}")
              until [ -z "${FILE}" ] ; do
                if [ ${BAD} -eq 0 ] ; then
                  mv "${FILE}" "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/badfiles/${FILE}"
                  printlog "Download ${FILE} is of unknown type. ${URL}" "failed"
                else
                  TRY=0
                  progupdatechk
                fi
                FILE=$(ls | head -n 1)
              done
            fi
          fi
        done
        cd "${WORKINGDIR}"
      fi
    done
  done
  }

###PROGRAM START
cd "${WORKINGDIR}"
echo "" >> "${LOGFILE}"
printlog ""
printlog "lpd started at $(date)"
printlog ""

###DEPENDENCY CHECK
pckmgrchk
depcheck wget
depcheck lynx
depcheck md5sum

###MENU
mkdir "${DOWNLOAD_DIRECTORY}/$(date +%Y-%m)" 2> /dev/null
mkdir "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/badfiles" 2> /dev/null
if [ -z "${DOWNLOAD_SELECTION}" ] ; then
  while [ 1 -eq 1 ] ; do
    UNKNOWN_OPT=1
    echo ""
    echo "Which batch would you like to download?"
    echo "all${CATEGORIES}"
    echo "clear_logs configure force help exit"
    read DOWNLOAD_SELECTION
    if [ "x${DOWNLOAD_SELECTION}" == "xall" ] ; then
      UNKNOWN_OPT=0
      DOWNLOAD_SET="${CATEGORIES}"
      progprocess
    fi
    if [ "x${DOWNLOAD_SELECTION}" == "xclear_logs" ]; then
      UNKNOWN_OPT=0
      mv "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/download_progress.log" "${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/download_progress_$(date).log"
      printlog "logs cleared:  renamed download_progress.log to download_progress_$(date).log"
      if [ "$(ls ${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/badfiles/)" != "" ] ; then
        rm -f ${DOWNLOAD_DIRECTORY}/${DOWNLOAD_DATE}/badfiles/* && printlog "bad files cleared"
      else printlog "no bad files to clear"
      fi
    fi
    if [ "x${DOWNLOAD_SELECTION}" == "xconfigure" ]; then
      UNKNOWN_OPT=0
      echo "Please enter the path to the folder you would like your new downloads to be dropped off:"
      read DOWNLOAD_DIRECTORY
    fi
    if [ "x${DOWNLOAD_SELECTION}" == "xhelp" ]; then
      UNKNOWN_OPT=0
      echo ""
      echo "Options: all antivirus creative utilities office clear_logs configure force help exit"
      echo "  all           download all program entries"
      echo "  clear_logs    clear the logs, rename the old ones, remove bad files"
      echo "  configure     change the download directory"
      echo "  force         toggle force downloading of programs already downloaded this month"
      echo "  help          prints this help message and exit"
      echo "  exit          end the program"
      echo ""
      echo "Welcome to Lynx Program Downloader. This program was created to automatically download files from the internet using the terminal-based Lynx web browser."
      echo "Programs are downloaded in batches designated by category in the database (the CSV file in the support directory). There, you can set different mirrors, names and categories for programs, as well as see their download history, filename and MD5 hash. URLs that match a given pattern will be downloaded with an existing download script (also found in the support directory), if available. Otherwise, they will be downloaded via wget."
      echo "If you would like to save where the downloads go by default, you can change the variable \${DOWNLOAD_DIRECTORY} in the CONFIG section at the beginning of the script."
      echo "If you would like to save the default downloader initials, put something inside the \${DOWNLOADER} variable at the beginning of the script."
      echo "If you would like to force downloads whether done this month or not, change the \${FORCE_DOWNLOADS} variable at the beginning of the script to 'on'."
    fi
    if [ "x${DOWNLOAD_SELECTION}" == "xforce" ]; then
      UNKNOWN_OPT=0
      if [ "x${FORCE_DOWNLOADS}" == "xoff" ] ; then
        FORCE_DOWNLOADS="on"
      else
        FORCE_DOWNLOADS="off"
      fi
      echo ""
      printlog "Toggle force programs downloaded this month to be downloaded again: ${FORCE_DOWNLOADS}"
    fi
    if [ "x${DOWNLOAD_SELECTION}" == "xexit" ]; then
      break
    fi
    if [ ${UNKNOWN_OPT} -eq 1 ] ; then
      DOWNLOAD_SET=$(downloadsetget "${DOWNLOAD_SELECTION}")
      if [ -z "${DOWNLOAD_SET}" ] ; then
        echo "I beg your pardon?"
      else
        printlog "Downloading: ${DOWNLOAD_SET}"
        progprocess
      fi
    fi
  done
else
  printlog "Downloading: ${DOWNLOAD_SET}"
  progprocess
fi
printlog ""
printlog "Finished at $(date)"
