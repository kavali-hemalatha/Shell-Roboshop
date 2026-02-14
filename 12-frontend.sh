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

dnf module disable nginx -y
dnf module enable nginx:1.24 -y
dnf install nginx -y
VALIDATE $? "installing nginx"

systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "enabling and starting nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "removing existing code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "downloading the code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip
VALIDATE $? "unzipping the code"

rm -rf /etc/nginx/nginx.conf

cp $script_path/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copying nginx conf file"

systemctl restart nginx 
VALIDATE $? "restarting nginx service"