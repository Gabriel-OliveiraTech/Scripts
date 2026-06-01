# Connect to EC2 Instance
#!/bin/bash
# This script uses AWS EC2 Instance Connect to send an SSH public key to an EC2 instance, allowing you to connect without needing to manage SSH keys on the instance.

read -p "Enter AWS CLI profile name: " profile
read -p "Enter EC2 instance ID: " instance_id
read -p "Enter username to connect with (default ec2-user): " username
read -p "Enter the path to your public key file (default ~/.ssh/id_rsa.pub): " key_path

echo "Connecting to EC2 instance..."
aws ec2-instance-connect send-ssh-public-key \
    --instance-id "$instance_id" \
    --profile "$profile" \
    --instance-os-user "${username:-ec2-user}" \
    --ssh-public-key file://${key_path:-~/.ssh/id_rsa.pub}

