# RadarrCollection
This script is designed to add, update and repair broken media in Radarr's Library

# Goal
My original intentions wwas to write a script I coudl run regularly to add movie series collections into Radarr, since it can't see deeper than the root movie folder where my movie series are a subfolder of the root movies in folders called "<Movie Series Name> Collection" and "<Movie Series Name> Anthology". These folders were auto created when I ran TinyMediaManger (https://www.tinymediamanager.org/) on my movies collections...I sson foudn out this broke Radarr's invnetory and had to remvoe over 100+ movies. It was a pain. I then decided to write this script to add them back but in the proper folder. 
  
# thanks Too
Benjamin Lemmond (https://github.com/code-glue/Imdb)

# Notes
I took code out of Ben's IMDB module and modified it a bit to meet my needs

# Script Status
This script is in a working progress. I plan on
 - Add logging
 - Change most write-hsot to verbose logging
 - change to use Radarr functions extensions to reduce main script
 - Generate nfo media file info using ffprobe
 - Store data to CliXML for faster processing.
