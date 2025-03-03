#!/usr/bin/bash

version="0.0.1"

logo="            _      __  __  _                  _                 _     
  ___ _   _| |__   \ \/ / | |_ _ __ __ _  ___| |_           ___| |__  
 / __| | | | '_ \   \  /  | __| '__/ _\` |/ __| __|  _____  / __| '_ \ 
 \__ \ |_| | |_) |  /  \  | |_| | | (_| | (__| |_  |_____| \__ \ | | |
 |___/\__,_|_.__/  /_/\_\  \__|_|  \__,_|\___|\__|         |___/_| |_|
 Version: $version
 Using: FFmpeg and FFprobe"

license="$logo

 MIT License

 Copyright (c) 2025 Alexander Holmgren

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 "

help="$logo


 subXtract-sh is a bash script to copy .srt files and extracting
 subtitles from .mkv, .mp4 and .avi files using FFmpeg and FFprobe.
 subXtract-sh makes it easy to copy and extract multiple subtitles
 from a directory and its sub directories. subXtract-sh extracts all
 subtitles from media files and adds language to subtitle file name.
 subXtract-sh does not overwrite files. subXtract-sh has currently
 only support for text based subtitles.


 Usage:
    ./subxtract.sh [-i inpath -o outdir] [options]

 Help:
    ./subxtract.sh -h

 License:
    ./subxtract.sh -l

 Options:         [Description]
    -h            Show help
    -v            Show version
    -l            Show license
    -i inpath     Specify path to input, file or directory
                    Default: Same directory where this script is located
    -o outdir     Specify path to output directory
                    Default: Same directory where the file is found
    -r            Scan a directory recursively
    -c            Copy only
    -e            Extract only
"

#                           #
###                       ###
#####     Variables     #####
###                       ###
#                           #

# Codec and file support
unsupported_codecs=("dvbsub" "dvdsub" "pgssub" "xsub" "dvb_subtitle" "dvd_subtitle" "hdmv_pgs_subtitle" "eia_608" "cc_dec")
supported_movies=("mkv" "mp4" "avi")
supported_subtitles=("srt")
subtitle_codecs=()

# String color variables
sc_error='\033[0;31m'
sc_success='\033[0;32m'
sc_warning='\033[0;33m'
sc_clear='\033[0m'

# Other global variables
destination=""
copy=false                  # Variable for checking if copy mode is active
extract=false               # Variable for checking if extract mode is active
recursive=false             # Variable for checking if recursive scanning is active

#                           #
###                       ###
#####     Functions     #####
###                       ###
#                           #

#
### Function to output error message
#

function printerr(){
  printf "${sc_error}$1${sc_clear}\n"
}


#
### Function to output warning message
#

function printwarn(){
  printf "${sc_warning}$1${sc_clear}\n"
}


#
### Function to output success message
#

function printsucc(){
  printf "${sc_success}$1${sc_clear}\n"
}


#
### Function to exit upon error
#

function errex(){
  # Write any messages if passed
  if [ ! -z "$1" ]; then
    printerr "$1"
  fi

  # Exit on error
  printerr "Exiting subXtract-sh due to error"
  exit 1
}


#
### Function to exit upon success
#

function succex(){
  # Write any messages if passed
  if [ ! -z "$1" ]; then
    printsucc "$1"
  fi

  # Exit on success
  printsucc "subXtract-sh was successfully executed, going to sleep\n"
  exit 0
}


#
### Function to extract subtitles from movies
#

function extract_subtitle(){
  source="$1"
  dest_dir="$2"

  # Get filename without directory and extension
  dest_base_file=$(t=${source##*/}; echo ${t%.*})

  # Process all subtitle streams found in file
  while IFS=',' read idx cdc lng tte; do

    # Check if codec is valid
    if ! printf '%s\0' "${subtitle_codecs[@]}" | grep -Fxqz -- "$cdc"; then
      printwarn "Found unsupported subtitle codec \"$cdc\", skipping"
      continue
    fi

    # Check if subtitle has a specified language
    if ! [ -z "$lng" ]; then
      lng=".$lng"
    fi

    # Check if subtitle has a specified tag
    if ! [ -z "$tte" ]; then
      tte=".${tte// /_}"
    fi

    # Define file name and path to destination
    dest_file="$dest_base_file$lng$tte.srt"
    dest_path="$dest_dir/$dest_file"

    # Check if subtitle stream already exists
    if [ -f "$dest_path" ] ; then
      printwarn "Subtitle \"$dest_file\" already exists in destination, skipping"
      continue
    fi

    printf "Extracting subtitle stream #$idx to file \"$dest_file\"\n"
    
    # Try extracting subtitle
    if ffmpeg -nostdin -hide_banner -loglevel error -i "$source" -map 0:"$idx" "$dest_path"; then
      printsucc "Successfully extracted subtitle stream #$idx to file \"$dest_file\""
    else
      printerr "Failed trying to extract subtitle stream #$idx to file \"$dest_file\""
    fi

  done < <(ffprobe -loglevel error -select_streams s -show_entries stream=index,codec_name:stream_tags=language,title -of csv=p=0 "${source}")
}


#
### Function to copy subtitles
#
function copy_subtitle(){
  source="$1"
  dest_dir="$2"
  dest_file=${source##*/} 
  dest_path="$dest_dir/$dest_file"

  # Check if subtitle stream already exists
  if [ -f "$dest_path" ] ; then
    printwarn "Subtitle \"$dest_file\" already exists in destination, skipping"
    return
  fi

  printf "Copying subtitle \"$dest_file\" to \"$destination\"\n"

  # Try copying subtitle
  if cp "$source" "$destination"; then
    printsucc "Successfully copied subtitle \"$dest_file\" to \"$destination\""
  else
    printerr "Failed trying to copy subtitle \"$dest_file\" to \"$destination\""
  fi
}


#
### function to route file action
#
function process_file(){
  source="$1"

  # Solve destination directory
  if [ -z "$destination" ]; then
    dest_dir=${source%/*}
  else
    dest_dir="$destination"
  fi

  print_header="======================================================================\nSource file: \"$source\"\nDestination: \"$dest_dir\"\n"
  print_footer="======================================================================\n\n"

  
  # Get extension of found file
  extension="${source##*.}"

  # Check if file is a supported media file
  if printf '%s\0' "${supported_movies[@]}" | grep -Fxqz -- "$extension"; then
    
    # Check if exctraction is active
    if ! $extract; then return; fi

    printf "$print_header"
    
    # Check if source file contains subtitle streams
    if ffprobe -loglevel error -hide_banner -i "$source" -show_streams -select_streams s | grep codec_type=subtitle -q ; then
      extract_subtitle "$source" "$destination"
    else
      printwarn "No subtitle streams found in source file"
    fi

    printf "$print_footer"
    return
  fi

  if printf '%s\0' "${supported_subtitles[@]}" | grep -Fxqz -- "$extension"; then    

    # Check if copy is active
    if ! $copy; then return; fi

    printf "$print_header"
    
    copy_subtitle "$source" "$destination"

    printf "$print_footer"
    return
  fi
}

function process_directory(){
  source="$1"

  # Loop trough all files in source directory
  for pth in "$source"/* ; do

    # Process directory if recursive
    if [ -d "$pth" ] && $recursive; then
      if [ "$destination" = "$pth" ]; then
        printwarn "Source directory is the same as destination, skipping"
        continue
      fi

      process_directory "$pth"
      continue
    fi

    # Process file
    if [ -f "$pth" ]; then
      process_file "$pth"
    fi

  done
}


#                                                                    #
###                                                                ###
#####                                                            #####
#######                                                        #######
#########                                                    #########
#########                 Script starts here                 #########
#########                                                    #########
#######                                                        #######
#####                                                            #####
###                                                                ###
#                                                                    #

#
### Parse flags
#

printf "$logo\n\n"

while getopts "hlvi:o:rce" flag; do
  case $flag in
    h)
    printf "$help\n" ; exit 0
    ;;

    l)
    printf "$license\n" ; exit 0
    ;;

    v)
    printf "subXtract-sh version: $version\n" ; exit 0
    ;;

    i)
    input=$(realpath "$OPTARG")
    ;;

    o)
    output=$(realpath "$OPTARG")
    ;;

    r)
    recursive=true
    ;;

    c)
    copy=true
    ;;

    e)
    extract=true
    ;;
  esac
done

# Set both copy and extract to true if none of those flags where set
if ! $copy && ! $extract; then
   copy=true
   extract=true
fi


#
### Check if ffmpeg and ffprobe is present on the system
#

ffexists=true

if ! command -v ffmpeg > /dev/null; then
  printerr "ffmpeg could not be found on the system"
  ffexists=false
fi

if ! command -v ffprobe > /dev/null; then
  printerr "ffprobe could not be found on the system"
  ffexists=false
fi

if ! $ffexists; then errex; fi


#
### Check if input is valid
#

if [ -z "$input" ]; then
  input="$PWD"
  printwarn "No input specified, using current directory: $input"
fi

if ! [[ -d "$input" || -f "$input" ]]; then errex "Input directory or file does not exists: $input"; fi


#
### Check if output is valid
#

if [ -z "$output" ]; then
  printwarn "No output directory specified, using same directory as source file(s)"
  printwarn "Copying will be disabled and extration of subtitle will be saved to the same directory as media file"

  # If extract is disabled, there is nothing to do
  if ! $extract; then succex "Extracting is disabled and by disabling copying, there is nothing to do"; fi

  copy=false
else
  if ! [ -d "$output" ]; then errex "Output directory does not exists: $output"; fi

  destination="$output"
fi


#
### Get supported ffmpeg subtitle codecs and remove image-based
#

for cdc in $(ffmpeg -codecs -hide_banner | grep -Po '(?<=D.S... )[^ ]*') ; do
  if ! printf '%s\0' "${unsupported_codecs[@]}" | grep -Fxqz -- "$cdc"; then
    subtitle_codecs+=("$cdc")
  fi
done


#
### Solve a single file
#

if [ -f "$input" ]; then
  process_file "$input"
  succex
fi


#
### Solve a directory
#

if [[ -d "$input" ]] ; then
  process_directory "$input"
  succex
fi