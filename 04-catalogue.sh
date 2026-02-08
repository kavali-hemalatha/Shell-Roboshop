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

dnf module disable nodejs -y &>>$log_file
VALIDATE $? "disabling nodejs default version"

dnf module enable nodejs:20 -y &>>$log_file
VALIDATE $? "enabling nodejs 20 version"

dnf install nodejs -y &>>$log_file
VALIDATE $? "installing nodejs"

id roboshop &>>$log_file #creating system user, if already exists it will skip
if [ id -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "creating system user"
else
    echo -e "system user already exist ... $Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "downloading code"

cd /app 
VALIDATE $? "moving to app directory"

unzip /tmp/catalogue.zip
VALIDATE $? "unzip catalogue code"

npm install
VALIDATE $? "installing dependencies"

cp $script_path/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "created systemctl service"

sed -i 's/<MONGODB-SERVER-IPADDRESS>/mongodb.daws-hemalatha.online/g' /etc/systemd/system/catalogue.service


