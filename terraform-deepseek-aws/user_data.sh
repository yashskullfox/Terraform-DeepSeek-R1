#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Log everything to a file for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user_data script execution..."

# 1. System Update and Prerequisite Installation
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# 2. Install NVIDIA Drivers
apt-get install -y ubuntu-drivers-common
ubuntu-drivers autoinstall

# 3. Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# 4. Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-container-toolkit

# A reboot is often necessary for the NVIDIA driver to load correctly.
systemctl restart docker
echo "Docker and NVIDIA drivers installed. Rebooting to apply driver changes..."
# The script will not continue after this, so subsequent steps must be idempotent or handled by a service.

# A more advanced setup would use a systemd service to complete the configuration.

# For this guide's purpose, we will run Ollama directly. In a real scenario, a reboot might be safer.
echo "Skipping reboot for guide simplicity, starting Ollama directly."

# 5. Run Ollama Docker Container
docker run -d --gpus=all \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama \
  ollama/ollama

echo "Ollama container is running."

# 6. Pull the DeepSeek Model
sleep 15

# Using 8B model as an example.
docker exec ollama ollama pull deepseek-r1:8b

echo "DeepSeek model pulled successfully. Setup complete."