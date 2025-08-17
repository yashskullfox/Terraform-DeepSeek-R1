variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type for the GPU node."
  type        = string
  default     = "g4dn.xlarge" # Suitable for models up to 14B quantized and fits in our home project budget
  #AWS	g4dn.xlarge	    NVIDIA T4	1	16	16	    4	~$0.53	    Up to 14B (Quantized)
  #AWS	g5.2xlarge	    NVIDIA A10G	1	24	32	    8	~$1.62	    Up to 32B (Quantized)
  #AWS	p4d.24xlarge	NVIDIA A100	8	640	1152	96	~$32.77	    671B (Quantized)
}


variable "r1-aws-ec2" {
  description = "The name of the EC2 Key Pair for SSH access."
  type        = string
  # Note: This key pair must be created in the AWS console beforehand and added here
}