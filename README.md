# Lynx-Program-Downloader

This is a bash shell script that downloads and sorts files from websites that require you to go through several pages to initiate a download, and it uses Lynx to do so.  It's been designed for a monthly download system a person could use to keep fresh downloads of new and updated programs ready at any time for use with a variety of different download sites such as majorgeeks.com.

This script is made to run on Linux and BSD systems that use Bash.  It has a smart dependency checker to make sure you have lynx, wget and MD5 installed, and if you don't, it will offer to install them for you (with apt- and rpm-based package managers only!).  You can specify sets of programs to download individually or all at once, use your initials to show who ran the backup when, and it also checks to see when a program was updated (changed) and keeps track of it all in a CSV document.

Please note, I am not trying to replace the apt- or rpm-based package systems already out there--this program will not install a thing on your hard drive.  In fact, if you wanted a command-line package manager for Windows, I'm sure Chocolatey would work better for you (chocolatey.org).  This script is just for a Linux system to download and organize files from the internet on sites that try to make it difficult.

For more information about Lynx (the real magic behind this script), visit lynx.isc.org

Right now, the program just works with majorgeeks.com.  But any site that is usable with common browsers can be supported by adding more lynx scripts to the /support directory.  Sites such as filehippo, sourceforge and more should be easily scriptable.

I am working on a version 1 release so far, and have a couple features I want to include before calling it ready yet--see the issue tracker for details.  Things like dynamic URL reading and multiple mirror processing.

If you want to keep regular, monthly, organized downloads, give this script a try!  On a server, you sould be able to schedule it as a CRON job with no user input using the -s option.

If you would like to save where the downloads go by default, you can change the variable $DOWNLOAD_DIRECTORY in the CONFIG section at the beginning of the script.

If you would like to save the default downloader initials, put something inside the $DOWNLOADER variable at the beginning of the script.

To specify which file extensions to consider as usable, edit support/whiteexts.txt to include your own!

Usage: pdu.sh -hr -i [USER'S INITIALS]... -s [DOWNLOAD SET] -c [DOWNLOAD DIRECTORY]

  -h            prints this help message and exit

  -i            Specify initials to be appended to file names

  -s            Choose from a predefined set of downloads

  -c            Configure download directory to place new downloads in

  -r            resets all logs
