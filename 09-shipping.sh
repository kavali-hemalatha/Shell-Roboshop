#!/bin/bash

R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[39m'

user_id=$(id -u)
log_folder="/var/log/Shell-Roboshop"
log_file="$log_folder/$0.log"
script_path=$PWD
mysql_host=mysql.daws-Hemalatha.online

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

id roboshop &>>$log_file #creating system user, if already exists it will skip
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "creating system user"
else
    echo -e "system user already exist ... $Y skipping $N"
fi

mkdir /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "downloading the code"

cd /app 
VALIDATE $? "moving to app directory"

unzip /tmp/shipping.zip
VALIDATE $? "unzipping the code"

cd /app 
mvn clean package
VALIDATE $? "installing dependencies"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "moving and renaming shipping"

cp $script_path/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "created systemctl service"

dnf install mysql -y 
VALIDATE $? "installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Loaded data into MySQL" "loading data into mysql....skipping"
else
    echo -e "data is already loaded ... $Y SKIPPING $N"
fi    

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "enabling and starting shipping"