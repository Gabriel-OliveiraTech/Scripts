#!/bin/bash

read -p "Enter AWS CLI profile name: " profile
read -p "Enter EC2 instance ID: " instance_id
read -p "Enter RDS endpoint or endpoint location: " endpoint
read -p "Enter the local port number to forward to (default 3306): " local_port
read -p "Enter the remote port number to forward to (default 5432): " remote_port

# Set default values if not provided
local_port=${local_port:-3306}
remote_port=${remote_port:-5432}

echo "Setting up SSM Tunnel..."
echo "Starting SSM Tunnel.."


##conect to the instance using SSM and forward the local port to the remote port on the RDS instance or endpoint
aws ssm start-session \
    --target "$instance_id" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$endpoint\"],\"portNumber\":[\"$remote_port\"],\"localPortNumber\":[\"$local_port\"]}" \
    --profile "$profile"

