#!/bin/bash

#This script expects an input file input.txt containing id,hash,url for an image
#the images will be stored on S3
#a log will be created containing the ids of the successfully uploaded images

#set semicolon as delimiter
IFS=';'

success=0
errors=0

#input.txt contains all images to be downloaded
cat input.txt | while read line; do

  #read line content into arr
  #id ${strarr[0]} | hash ${strarr[1]} | url ${strarr[2]}
  read -a strarr <<< "$line"

  # need to base64 encode otherwise image is corrupted
  # PIPESTATUS[0] ensures that the curl exit status is passed to $?
  # -s silent mode| -f fail instead of returning http codes | --connect.. max time for connecting | -m max time for whole download
  image=$(curl -s -f --connect-timeout 2 -m 6 ${strarr[2]} | base64 ; exit ${PIPESTATUS[0]})
  if [ $? -eq 0 ]; then
    echo ${image} | base64 -D | aws s3 cp - s3://fashioncloud/test/${strarr[1]}_original.jpg &&
    echo ${strarr[0]} >> log.txt
    # ^^^ append id of successfully written record to log file
    let "success=success+1"
  else
    let "errors=errors+1"
  fi
  #ouput progress without printing newlines
  printf "\ruploaded: ${success} | errors: ${errors}"
done
echo 


#for local testing purposes replace the aws s3 upload line with
#echo ${image} | base64 -D > ${strarr[1]}_original.jpg &&