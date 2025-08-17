# AWS Setup and Terraform Deployment

Using the approach from this guide: https://builder.aws.com/content/2sEuHQlpyIFSwCkzmx585JckSgN/deploying-deepseek-r1-distill-model-on-amazon-ec2

## What you need
- An AWS account and an IAM user with Access Key and Secret Key
- AWS CLI installed on your computer
- Terraform installed on your computer
- An SSH key pair in AWS (key name) and the private key file on your computer

## 1) Set your AWS credentials (one-time setup)
Use AWS CLI to save your credentials on your computer. Terraform will read these automatically.

```bash
aws configure
```
Fill the answers like this:

- AWS Access Key ID: YOUR_ACCESS_KEY
- AWS Secret Access Key: YOUR_SECRET_KEY
- Default region name: us-east-1
- Default output format: json

## 2) Deploy with Terraform
Run these commands inside the `terraform-deepseek-aws` folder.

1. Initialize Terraform (downloads needed plugins):
```bash
terraform init
```

2. See the plan (replace `your-key-name` with your AWS key pair name):
```bash
terraform plan -var="key_name=r1-aws-ec2"
```
Check the plan to understand what Terraform will create.

3. Apply (create the resources in AWS):
```bash
terraform apply -var="key_name=r1-aws-ec2" -auto-approve
```
This may take a few minutes. It will start an EC2 instance and run the setup script.

## 3) Connect to the server and verify
1. Get the public IP from the Terraform output after apply finishes.
2. SSH into the instance using your private key file:
```bash
ssh -i /path/to/your-key.pem ubuntu@<INSTANCE_PUBLIC_IP>
```
3. If something is not working, check the setup logs:
```bash
tail -f /var/log/user-data.log
```
4. Check that the Ollama container is running:
```bash
docker ps
```
You should see a container named `ollama/ollama`.

## 4) Test the model API endpoint
From your local machine, send a test request using curl (replace `<INSTANCE_PUBLIC_IP>`):

```bash
curl http://<INSTANCE_PUBLIC_IP>:11434/api/generate -d '{
  "model": "deepseek-llm:8b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```
If it works, you will get a JSON response with the model's answer. This shows that the cloud server, the container, and the model API are all working.

## 5) Clean up (to stop charges)
When you finish testing, destroy everything to avoid AWS charges:

```bash
terraform destroy -var="key_name=r1-aws-ec2" -auto-approve
```
Terraform will remove all resources it created.

---
Tips:
- Keep your Access Key and Secret Key safe. Do not share them.
- Make sure the key pair name you pass in `key_name` exists in AWS, and you have the matching `.pem` file on your computer.
