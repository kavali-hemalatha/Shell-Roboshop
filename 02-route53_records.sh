    #!/bin/bash

    sg_id=sg-0c88955dfe5d1953a
    ami_id=ami-0220d79f3f480ecf5
    zone_id=Z10032441QWS0L4330FZ5
    domain_name=daws-Hemalatha.online


    for INSTANCE in $@
    do
        INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $ami_id \
        --instance-type t3.micro \
        --security-group-ids $sg_id \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

        if [ $INSTANCE == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
        )
                echo "Instance ID: $INSTANCE_ID"
                echo "Public IP: $IP"
                RECORD_NAME="$domain_name"
        else
            IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
        )
                echo "Instance ID: $INSTANCE_ID"
                echo "Private IP: $IP"
                RECORD_NAME="$INSTANCE.$domain_name"
        fi     
            aws route53 change-resource-record-sets \
            --hosted-zone-id $zone_id \
            --change-batch '
                {
                    "Comment": "Updating DNS record",
                    "Changes": [
                            {
                                "Action": "UPSERT",
                                "ResourceRecordSet": {
                                    "Name": "'$domain_name'",
                                    "Type": "A",
                                    "TTL": 1,
                                    "ResourceRecords": [
                                    {
                                      "Value": "'$IP'"
                                    }
                                ]
                            }
                        }
                    ]
                }    
                '
                echo "record updated for $INSTANCE"
    done