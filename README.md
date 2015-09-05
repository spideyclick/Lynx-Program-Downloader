# Lynx-Program-Downloader

This is a bash shell script that downloads and sorts files from websites that require you to go through several pages to initiate a download, and it uses Lynx to do so.  It's been designed for a monthly download system I am in charge of at work.

This script is made to run on Linux distributions that use Bash (Doesn't work so well with regular shell right now).

It first checks what package manager you are using, then if you have lynx installed.  If you have an rpm or dpkg based system, it will ask you to download Lynx if you do not have it.

With the dependencies satisfied, it will present a menu with several sets of different programs you can download, such as antivirus, utilities and creative.

Please note, I am not trying to replace the apt- or rpm-based package systems already out there--this program will not install a thing on your hard drive.  In fact, if you wanted a command-line package manager for Windows, I'm sure Chocolatey would work better for you (chocolatey.org).  This script is just for a Linux system to download and organize files from the internet on sites that try to make it difficult.

For more information about Lynx (the real magic behind this script), visit lynx.isc.org

Right now, the program just works with majorgeeks.com.  But any site that is usable with common browsers can be supported by adding more lynx scripts to the /support directory.  Sites such as filehippo, cnet and more should be easily scriptable.

I am working on an update tracking system so you will know if your download is different from the last one using MD5 hashes and a CSV database.  I also have support for plain wget URL's in the works--see the v1 branch for some of the most recent changes.  I don't consider this to be in a 1.0 release until those features are working.

If you want to keep regular, monthly, organized downloads, give this script a try!  On a server, you sould be able to schedule it as a CRON job with no user input using the -s option.

If you would like to save where the downloads go by default, you can change the variable $DOWNLOAD_DIRECTORY in the CONFIG section at the beginning of the script.

If you would like to save the default downloader initials, put something inside the $DOWNLOADER variable at the beginning of the script.

Usage: pdu.sh -hr -i [USER'S INITIALS]... -s [DOWNLOAD SET] -c [DOWNLOAD DIRECTORY]

  -h            prints this help message and exit

  -i            Specify initials to be appended to file names

  -s            Choose from a predefined set of downloads

  -c            Configure download directory to place new downloads in

  -r            resets all logs

Welcome to the Program Downloader Utility (PDU).  This program was created to automatically download programs from the internet using the terminal-based Lynx web browser.
Configuration files can be found in the support/ directory.  Every URL given in the categories will be downloaded into a matching subfolder.  At this time, only websites from majorgeeks.com are supported, and you will want to put the download page in line, NOT the general information page.  This allows you to choose which mirror you'd like to download.  For all other direct downloads, you can put them in 'unsorted', and they will be downloaded via wget.
