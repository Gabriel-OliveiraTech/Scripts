# Connect to EC2 Instance
#!/bin/bash
# NOTE: if you want to connect to an EC2 instance using EC2 Instance Connect tunnel, first run EC2-instance-connect-send-key.sh to send your SSH public key to the instance before running this script.

read -p "Enter AWS CLI profile name: " profile
read -p "Enter EC2 instance ID: " instance_id
echo "Connecting to EC2 instance..."
aws ec2-instance-connect ssh \
    --instance-id "$instance_id" \
    --profile "$profile" \