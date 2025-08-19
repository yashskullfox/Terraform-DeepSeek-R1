# Azure Setup and Terraform Deployment

## What you need
- Azure account
- Azure CLI installed
- Terraform installed
- SSH key pair on your computer (public key like `~/.ssh/id_rsa.pub`, private key `~/.ssh/id_rsa`)

Tip: If you do not have SSH keys, create them:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

## 1) Log in to Azure (one-time setup)
1. Login (this opens a browser to sign in):
```bash
az login
```
2. If you have many subscriptions, select the one you want:
```bash
az account set --subscription "yash-azure-vm"
```
Terraform will use this login automatically.

## 2) Deploy with Terraform
Run these commands inside the `terraform-deepseek-azure` folder.

1. Initialize Terraform (downloads required plugins):
```bash
terraform init
```

2. See the plan (change the key path if different):
```bash
terraform plan -var="ssh_public_key_path=~/.ssh/id_rsa.pub"
```
Review what will be created.

3. Apply (create resources in Azure):
```bash
terraform apply -var="ssh_public_key_path=~/.ssh/id_rsa.pub" -auto-approve
```
This will create the VM and run the setup. It may take a few minutes.

## 3) Connect to the VM and verify
1. Get the VM public IP from the Terraform output.
2. SSH into the VM using your private key:
```bash
ssh -i ~/.ssh/id_rsa azureuser@<VM_PUBLIC_IP>
```
3. If something is not working, check the cloud-init logs:
```bash
cat /var/log/cloud-init-output.log
cat /var/log/cloud-init-runcmd.log
```
4. Check that the Ollama container is running:
```bash
docker ps
```
You should see a container named `ollama/ollama`.

## 4) Test the model API endpoint
From your local machine, send a test request to the VM (replace `<VM_PUBLIC_IP>`):
```bash
curl http://<VM_PUBLIC_IP>:11434/api/generate -d '{
  "model": "deepseek-llm:7b-chat",
  "prompt": "What are the main differences between AWS and Azure?",
  "stream": false
}'
```
If it works, you will get a JSON response with the model’s answer.

## 5) Clean up (to stop charges)
When you finish testing, destroy everything:
```bash
terraform destroy -var="ssh_public_key_path=~/.ssh/id_rsa.pub" -auto-approve
```
Terraform will remove all resources it created.

---