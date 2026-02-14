#!/bin/bash

R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[39m'

user_id=$(id -u)
log_folder="/var/log/Shell-Roboshop"
log_file="$log_folder/$0.log"
script_path=$PWD
MONGODB_HOST=mongodb.daws-hemalatha.online

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

dnf module disable redis -y &>>log_file
VALIDATE $? "disabling existing version"

dnf module enable redis:7 -y &>>log_file
VALIDATE $? "enabling 7th version"

dnf install redis -y &>>log_file
VALIDATE $? "installing redis"

sed -i -e 's/12.0.0.7/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections"

systemctl enable redis &>>log_file
systemctl start redis 
VALIDATE $? "enabling and starting redis"