variable "azure_location" {
  description = "The Azure region to deploy resources in."
  type        = string
  default     = "East US"
}

variable "vm_size" {
  description = "The Azure VM size for the GPU node."
  type        = string
  default     = "Standard_NC4as_T4_v3" # Suitable for models up to 14B quantized
  # Azure	Standard_NC4as_T4_v3	    NVIDIA T4	1	16	28	    4	~$0.53	  Up to 14B (Quantized)
  # Azure	Standard_NC24ads_A100_v4	NVIDIA A100	1	80	220	    24	~$3.67	  Up to 70B (Quantized)
  # Azure	Standard_ND96amsr_A100_v4	NVIDIA A100	8	640	1900	96	~$27.39	  671B (Quantized)
}

variable "admin_username" {
  description = "The admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file for authentication."
  type        = string
  # Example: "~/.ssh/id_rsa.pub"
}