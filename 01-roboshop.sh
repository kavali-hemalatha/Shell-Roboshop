#!/bin/bash

sg_id=sg-0c88955dfe5d1953a
ami_id=ami-0220d79f3f480ecf5


for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
     --image-id $ami_id \
     --instance-type t3.micro \
     --security-group-ids $sg_id \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$instance}]' \
     --query 'Instances[0].InstanceId' \
     --output text)

     if [ $instance=='frontend' ]; then
       IP=(
          aws ec2 describe-instances \
          --instance-ids $INSTANCE_ID \
          --query 'Reservations[0].Instances[0].PublicIpAddress' \
          --output text
       )
               echo "Instance ID: $INSTANCE_ID"
               echo "Public IP: $IP"
    else
        IP=(
          aws ec2 describe-instances \
          --instance-ids $INSTANCE_ID \
          --query 'Reservations[0].Instances[0].PrivateIpAddress' \
          --output text
       )
               echo "Instance ID: $INSTANCE_ID"
               echo "Private IP: $IP"      
    fi            
            
done