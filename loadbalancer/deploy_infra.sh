#!/bin/bash
#set the ansible to the path of the cfg file.
export ANSIBLE_CONFIG=./ansible.cfg

# Run Terraform
terraform init
terraform apply -auto-approve

# Extract instance IPs and ELB DNS from Terraform output
INSTANCE_IPS=$(terraform output -json instance_ips | jq -r '.[]')
ELB_DNS=$(terraform output -raw elb_dns_name) # Ensure this line is uncommented to target the ELB

# Create an Ansible inventory file
echo "[app_servers]" > inventory.ini
for ip in $INSTANCE_IPS; do
    echo "$ip ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/dave-key.pem" >> inventory.ini
done

echo "[load_balancer]" >> inventory.ini
echo "$ELB_DNS" >> inventory.ini

# Run Ansible playbook
ansible-playbook -i inventory.ini playbook.yaml

# Prompt the user to destroy the infrastructure
read -p "Do you want to destroy the infrastructure? (y/n) " answer
if [[ $answer == "y" ]]; then
    terraform destroy -auto-approve
fi
