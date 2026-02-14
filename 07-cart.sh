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

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "downloading code"

cd /app 
VALIDATE $? "moving to app diirectory"

rm -rf /app/*
VALIDATE $? "removing existing content"

unzip /tmp/cart.zip
VALIDATE $? "unzipping code"

npm install 
VALIDATE $? "installing dependencies"

cp $script_path/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copying cart service"

sed -i -e 's/<REDIS-SERVER-IP>/redis.daws-Hemalatha.online/g' -e 's/<CATALOGUE-SERVER-IP>/catalogue.daws-Hemalatha.online/' /etc/systemd/system/cart.service
VALIDATE $? "changing ip address in cart service"

systemctl daemon-reload
systemctl enable cart 
systemctl start cart
VALIDATE $? "enabling and starting cart service"