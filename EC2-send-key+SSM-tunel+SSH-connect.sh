#!/bin/bash
# Connects to a private EC2 instance through a bastion, via SSM + EC2 Instance Connect:
#   1. Sends SSH public key to the TARGET instance (valid for 60s)
#   2. Opens SSM ToRemoteHost tunnel: localhost:<local_port> -> (bastion) -> target:22
#   3. SSHes into the target through the tunnel before the key expires

read -p "AWS CLI profile name (e.g. default, prod, dev): " profile
read -p "Bastion EC2 instance ID - SSM target (e.g. i-0bastion...): " bastion_id
read -p "Target EC2 instance ID - destination (e.g. i-0target...): " target_id
read -p "Target endpoint/IP to reach via bastion (e.g. 10.0.1.20 or host.internal): " endpoint
read -p "OS username to connect as [ec2-user]: " username
read -p "Path to SSH public key [~/.ssh/id_rsa.pub]: " pub_key_path
read -p "Local port to expose SSH tunnel on [2222]: " local_port

username=${username:-ec2-user}
pub_key_path=${pub_key_path:-~/.ssh/id_rsa.pub}
pub_key_path="${pub_key_path/#\~/$HOME}"
local_port=${local_port:-2222}
priv_key_path="${pub_key_path%.pub}"

if [ ! -f "$pub_key_path" ]; then
    echo "Error: public key not found at '$pub_key_path'."
    exit 1
fi

if [ ! -f "$priv_key_path" ]; then
    echo "Error: private key not found at '$priv_key_path'."
    exit 1
fi

echo ""
echo "[1/3] Sending SSH public key to target $target_id via EC2 Instance Connect (valid for 60s)..."
aws ec2-instance-connect send-ssh-public-key \
    --instance-id "$target_id" \
    --instance-os-user "$username" \
    --ssh-public-key "file://${pub_key_path}" \
    --profile "$profile"

if [ $? -ne 0 ]; then
    echo "Error: failed to send SSH public key. Aborting."
    exit 1
fi

echo ""
echo "[2/3] Starting SSM tunnel via bastion $bastion_id (localhost:$local_port -> $endpoint:22)..."
aws ssm start-session \
    --target "$bastion_id" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$endpoint\"],\"portNumber\":[\"22\"],\"localPortNumber\":[\"$local_port\"]}" \
    --profile "$profile" </dev/null >/dev/null 2>&1 &

SSM_PID=$!

TIMEOUT=30
ELAPSED=0
printf "Waiting for tunnel"
until nc -z localhost "$local_port" 2>/dev/null; do
    printf "."
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo ""
        echo "Error: tunnel did not open after ${TIMEOUT}s. Aborting."
        kill "$SSM_PID" 2>/dev/null
        exit 1
    fi
done
echo " ready."

echo ""
echo "[3/3] Connecting via SSH through localhost:$local_port..."
ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -i "$priv_key_path" \
    -p "$local_port" \
    "$username@localhost"

SSH_EXIT=$?

kill "$SSM_PID" 2>/dev/null
wait "$SSM_PID" 2>/dev/null
echo "SSM tunnel closed."
exit $SSH_EXIT
