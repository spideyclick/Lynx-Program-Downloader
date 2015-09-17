# Lynx-Program-Downloader

Welcome to Lynx Program Downloader. This program was created to automatically download files from the internet using the terminal-based Lynx web browser. It's designed for a monthly download system that a person could use to keep fresh downloads of new and updated programs ready at any time for use with a variety of different download sites. On a server, you could schedule it as a CRON job to run with no user input using the -s option.

Programs are downloaded in batches designated by category in the database (the CSV file in the support directory). There, you can set different mirrors, names and categories for programs, as well as see their download history, filename and MD5 hash. URLs that match a given pattern will be downloaded with an existing download script (also found in the support directory), if available. Otherwise, they will be downloaded via wget.

It runs on systems that use Bash and includes a smart dependency checker to make sure you have lynx, wget and MD5 installed, and if you don't, it will offer to install them for you (with apt- and rpm-based package managers).

If you would like to save where the downloads go by default, you can change the variable $DOWNLOAD_DIRECTORY in the CONFIG section at the beginning of the script.
If you would like to save the default downloader initials, put something inside the $DOWNLOADER variable at the beginning of the script.
If you would like to force downloads whether done this month or not, change the $FORCE_DOWNLOADS variable at the beginning of the script to 'on'.

Please note, I am not trying to replace the apt-, rpm- or chocolatey-based package systems already out there. This program will not install a thing, but instead downloads and organizes files from the internet on sites that try to make it difficult to do batch downloads.

For more information about Lynx, visit lynx.isc.org

# Database Format

The database that keeps track of download date, MD5 hash, filename and URLs can be found under the support directory. There are a couple quirks that it has:
 - Columns need to be separated by the '>' character. I can't think of a better one, and it expects that character in many places in the program now.
 - 64-bit applications need to have a 64 come before the name. Reason being, if the program sees 'x' and 'x_64', it will see the two entries as one, and you may miss out on a download. '64_x' avoids this problem.
 - You need to watch which URLS you put in. http://website/program vs http://website/program/download makes all the difference to the download scripts, because those are typically very different pages.
 - Keep in mind, I have made this program with the intent of being easily scriptable. If you find a site you come to for many different downloads, go ahead and save the actions it takes to download from a web page and submit it to the git repo! This usually requires a command such as: lynx -accept_all_cookies -cmd_log="cmd.txt" http://your/URL/here

# Command Format

Usage: pdu.sh -hrf -i [USER'S INITIALS]... -s [\"CATGORIES CATEGORIES\"] -c [DOWNLOAD_DIRECTORY]
  -h    prints this help message and exit
  -r    resets all logs, remove bad files
  -f    force downloading of programs already downloaded this month
  -i    Specify initials to be appended to file names
  -s    Choose a set of downloads according to category in the CSV file
  -c    Configure download directory to place new downloads

Lynx Program Downloader 1.0
Licenced under the GNU General Public License, Version 2
Authored by Zachary (spideyclick) Hubbell. Code maintained at GitHub (send bug reports here!):
https://github.com/spideyclick/Lynx-Program-Downloader