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

dnf install python3 gcc python3-devel -y
VALIDATE $? "installing python"

id roboshop &>>$log_file #creating system user, if already exists it will skip
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "creating system user"
else
    echo -e "system user already exist ... $Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
VALIDATE $? "downloading payment code"

cd /app
VALIDATE $? "moving to app directory"

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/payment.zip
VALIDATE $? "unzipping the code"

cd /app
pip3 install -r requirements.txt
VALIDATE $? "installing dependencies"

cp $script_path/payment.service /etc/systemd/system/payment.service
VALIDATE $? "copying systemctl service"

systemctl daemon-reload
systemctl enable payment 
systemctl start payment
VALIDATE $? "enabling and starting payment"