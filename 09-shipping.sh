#!/bin/bash

R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[39m'

user_id=$(id -u)
log_folder="/var/log/Shell-Roboshop"
log_file="$log_folder/$0.log"
script_path=$PWD

if [ $user_id -ne 0 ]; then
echo -e "this script needs to be run with $R root $N user" | tee -a $log_file
exit 1
fi

mkdir -p $log_folder

VALIDATE(){
    if [ $1 -ne 0 ]; then
echo -e "$R $2.....FAILURE" | tee -a $log_file
exit 1
else
echo -e "$G $2.....SUCCESS" | tee -a $log_file
fi
}

dnf install maven -y
VALIDATE $? "installing java"

