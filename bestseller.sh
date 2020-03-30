#!/bin/bash

#This script expects an input file input.txt containing id,hash,url for an image
#the images will be stored on S3
#a log will be created containing the ids of the successfully uploaded images
#
#on ubuntu execute this script with 'sudo bash bestseller.sh'

export PATH="/home/ubuntu/bin:/home/ubuntu/.local/bin:/home/ubuntu/bin:/home/ubuntu/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin::$PATH"
#export AWS_ACCESS_KEY_ID=
#export AWS_SECRET_ACCESS_KEY=

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -i|--input)
    INPUT="$2"
    shift # past argument
    shift # past value
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#set semicolon as delimiter
IFS=';'

success=0
errors=0

#input.txt contains all images to be downloaded
cat ${INPUT} | while read line; do

  #read line content into arr
  #id ${strarr[0]} | hash ${strarr[1]} | url ${strarr[2]}
  read -a strarr <<< "$line"

  # need to base64 encode otherwise image is corrupted
  # PIPESTATUS[0] ensures that the curl exit status is passed to $?
  # -s silent mode| -f fail instead of returning http codes | --connect.. max time for connecting | -m max time for whole download
  image=$(curl -s -f --connect-timeout 2 -m 15 ${strarr[2]} | base64 ; exit ${PIPESTATUS[0]})
  if [ $? -eq 0 ]; then
    echo ${image} | base64 -d | aws s3 cp - s3://fashioncloud/production/images/${strarr[1]}_original.jpg
    if [ $? -eq 0 ]; then
      echo ${strarr[0]} >> {INPUT[@]/\.txt/}_log.txt
      # ^^^ append id of successfully written record to log file
      let "success=success+1"
    else
      let "errors=errors+1"
      echo "${strarr[0]};${strarr[1]};${strarr[3]}" >> ${INPUT[@]/\.txt/}_error_log.txt
    fi
  else
    let "errors=errors+1"
    echo "${strarr[0]};${strarr[1]};${strarr[3]}" >> ${INPUT[@]/\.txt/}_error_log.txt
  fi
  #ouput progress without printing newlines
  printf "\ruploaded: ${success} | errors: ${errors}"
done
echo


#for local testing purposes replace the aws s3 upload line with
#echo ${image} | base64 -D > ${strarr[1]}_original.jpg &&