# Start an SSM Session
#!/bin/bash

read -p "Enter AWS CLI profile name: " profile
read -p "Enter EC2 instance ID: " instance_id
echo "Starting SSM Session..."
aws ssm start-session \
    --target "$instance_id" \
    --profile "$profile" \
    