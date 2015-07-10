# Lynx-Program-Downloader
This is a bash shell script that downloads, updates and sorts files from websites that require you to go through several pages to initiate a download, and it uses Lynx to do so.

This script is made to run on Linux distributions that use Bash (Doesn't work so well with regular shell right now).

It first checks what package manager you are using, then if you have lynx installed.  If you have an rpm or dpkg based system, it will ask you to download Lynx if you do not have it.

With the dependencies satisfied, it will present a menu with several sets of different programs you can download, such as antivirus, utilities and creative.

Please note, I am not trying to replace the apt- or rpm-based package systems already out there.  In fact, if you want the same thing for Windows, I'm sure Chocolatey would work better for you (chocolatey.org).  This script is for a Linux system to download, update and organize files from the internet on sites that try to make it difficult.

For more information about Lynx (the real magic behind this script), visit lynx.isc.org

Right now, the program just works with majorgeeks.com and regular wget URL's.  I'd like to add support for sites such as filehippo, cnet and more in the future.  Anybody should be able to do so by scripting the Lynx side of it once the program is stable.
