# Connect to EC2 Instance
#!/bin/bash
# This script uses AWS EC2 Instance Connect to open a tunnel to an EC2 instance, allowing you to forward local ports to remote ports on the instance.
# Note: This requires the EC2 instance to have the EC2 Instance Connect agent installed and running.
# Note: Requires send-ssh-public-key to the instance. First run EC2-instance-connect-send-key.sh to send your SSH public key to the instance before running this script.

read -p "Enter AWS CLI profile name: " profile
read -p "Enter EC2 instance ID: " instance_id
read -p "Enter the local port number to forward to (default 3306): " local_port
read -p "Enter the remote port number to forward to (default 3306): " remote_port
echo "Connecting to EC2 instance..."
aws ec2-instance-connect open-tunnel \
  --instance-id "$instance_id" \
  --profile "$profile" \
  --local-port "${local_port:-3306}" \
  --remote-port "${remote_port:-3306}"