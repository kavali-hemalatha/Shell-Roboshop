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

dnf module disable nodejs -y
VALIDATE $? "disabling existing version"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling 20 version"

dnf install nodejs -y
VALIDATE $? "installing nodejs"

id roboshop &>>$log_file #creating system user, if already exists it will skip
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "creating system user"
else
    echo -e "system user already exist ... $Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "downloding the code"

cd /app
VALIDATE $? "moving to app directory"

rm -rf /app/*
VALIDATE $? "removing existing content"

unzip /tmp/user.zip
VALIDATE $? "unzipping code"

npm install 
VALIDATE $? "installing dependencies"

cp $script_path/user.service /etc/systemd/system/user.service
VALIDATE $? "created systemctl service"

sed -i -e 's/<MONGODB-SERVER-IP-ADDRESS>/mongodb.daws-Hemalatha.online/g' -e 's/<REDIS-IP-ADDRESS>/redis.daws-Hemalatha.online/g' /etc/systemd/system/user.service
VALIDATE $? "Changing ip address in user service"

systemctl daemon-reload
VALIDATE $? "reloading service"

systemctl enable user 
systemctl start user
VALIDATE $? "enabling and starting user sevice"

