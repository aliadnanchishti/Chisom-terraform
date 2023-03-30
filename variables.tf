variable "subnets" {
  description = "List of subnet IDs to use for instance(s). Leave empty to use dad private subnets."
  default     = []
}

variable "name" {
  description = "Name to be used on all resources as prefix"
  default     = "ec2-sample"
}

variable "iam_name" {
  description = "Name to be used for IAM role. Leave blank to generate one based on var.name"
  default     = ""
}

variable "ami_id" {
  description = "AMI ID used to launch the EC2 instance. Leave blank to use AMI looked up via var.ami_filter, var.ami_owner."
  default     = ""
}

variable "ami_owner" {
  type        = list(string)
  description = "The account ID of the owner of the AMI to be looked up (if an exact AMI is not provided)"
  default     = ["self"]
}

variable "ami_name_filter" {
  description = "The AMI name filter used to find an AMI"
  default     = "xyz_ubuntu16_base-master*"
}

variable "instance_count" {
  description = "Number of instances to launch"
  default     = 1
}

variable "placement_group" {
  description = "The Placement Group to start the instance in"
  default     = ""
}

variable "tenancy" {
  description = "The tenancy of the instance (if the instance is running in a VPC). Available values: default, dedicated, host."
  default     = "default"
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  default     = false
}

variable "disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection"
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance" # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html#Using_ChangingInstanceInitiated"
  default     = ""
}

variable "instance_type" {
  description = "The type of instance to start"
  default     = "t2.medium"
}


variable "kms_key_id" {
  default     = "alias/dad-basic-data-kms-key"
  description = "The KMS key ID used to encrypt the EBS snapshots."
}

variable "key_pair_name" {
  default     = "xyz_devops_dad_aws"
  description = "Key pair used for connectivity to instance."
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  default     = false
}

#variable "vpc_security_group_ids" {
#  description = "A list of security group IDs to associate with"
#  type        = "list"
#}

variable "security_group_ingress_list" {
  description = "Ingress map for security group"
  type        = list(map(any))

  # Format is:
  # [{
  #   "from_port"   = ""
  #   "to_port"     = ""
  #   "protocol"    = ""
  #   "cidr_blocks" = ""
  # },]
  default = []

}

variable "security_group_egress_list" {
  description = "Engress map for security group"
  type        = list(map(any))

  default = [
    {
      "from_port"   = "-1"
      "to_port"     = "-1"
      "protocol"    = "-1"
      "cidr_blocks" = "0.0.0.0/0"
    }
  ]
}

variable "create_security_group" {
  description = "Do you want to create a security group"
  default     = true
}

variable "associate_public_ip_address" {
  description = "If true, the EC2 instance will have associated public IP address"
  default     = false
}

variable "private_ip" {
  description = "Private IP address to associate with the instance in a VPC"
  type        = list(string)
  default     = []
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs."
  default     = true
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  default     = ""
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile."
  default     = ""
}

variable "policies" {
  description = "List of policies (in text form) used for IAM role for EC2 instances"
  type        = list(string)
  default     = []
}

variable "policy_list" {
  description = "List of policy files used for IAM role for EC2 instances"
  type        = list(map(string))

  # Format is:
  # [
  #   {
  #     name   = ""
  #     policy = ""
  #   },
  # ]
  default = []
}

variable "attach_existing_policy_list" {
  default     = []
  description = "A list of pre-existing policies to attach. For example, AWS managed policies can be listed here."
}

variable "ipv6_address_count" {
  description = "A number of IPv6 addresses to associate with the primary network interface. Amazon EC2 chooses the IPv6 addresses from the range of your subnet."
  default     = 0
}

variable "ipv6_addresses" {
  description = "Specify one or more IPv6 addresses from the range of the subnet to associate with the primary network interface"
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  default     = {}
  type        = map(string)
}

variable "volume_tags" {
  description = "A mapping of tags to assign to the devices created by the instance at launch time"
  default     = {}
  type        = map(string)
}

variable "root_block_device_size" {
  description = "Customize details about the root block device of the instance. See Block Devices below for details"
  default     = "30"
}

variable "root_block_device_type" {
  description = "Customize details about the root block device of the instance. See Block Devices below for details"
  default     = "gp2"
}

variable "ephemeral_block_device" {
  description = "Customize Ephemeral (also known as Instance Store) volumes on the instance"
  default     = []
}

variable "network_interface" {
  description = "Customize network interfaces to be attached at instance boot time"
  default     = []
}

variable "use_num_suffix" {
  description = "Always append numerical suffix to instance name, even if instance_count is 1"
  default     = "false"
}

variable "ebs_required" {
  description = ""
  default     = 0
}

variable "ebs_type" {
  description = ""
  default     = "gp2"
}

variable "ebs_size" {
  description = ""
  default     = 1
}

variable "ebs_skip_destroy" {
  description = "Set this to true if you do not wish to detach the volume from the instance to which it is attached at destroy time, and instead just remove the attachment from Terraform state. This is useful when destroying an instance which has volumes created by some other means attached."
  default     = "false"
}

variable "ebs_force_detach" {
  description = "Set to true if you want to force the volume to detach. Useful if previous attempts failed, but use this option only as a last resort, as this can result in data loss."
  default     = "false"
}

variable "dad_crowdstrike_install" {
  type        = bool
  default     = true
  description = "Boolean (true/false) to determine how Crowdstrike dad install tag should be set."
}

variable "dad_qualys_install" {
  type        = bool
  default     = true
  description = "Boolean (true/false) to determine how Qualys dad install tag should be set."
}

variable "env" {
  description = "The logical environment name for the instance"
  default     = ""
}

variable "ebs_device_list" {
  description = "device list for EC2 mapping"
  type        = list(string)
  default     = ["/dev/sde", "/dev/sdf", "/dev/sdg", "/dev/sdh", "/dev/sdi", "/dev/sdj", "/dev/sdk", "/dev/sdl", "/dev/sdm", "/dev/sdn", "/dev/sdo", "/dev/sdp", "/dev/sdq", "/dev/sdr", "/dev/sds", "/dev/sdt", "/dev/sdu", "/dev/sdv", "/dev/sdw", "/dev/sdx", "/dev/sdy", "/dev/sdz"]
}

variable "ebs_encrypted" {
  description = "Are the attached EBS volumes encrypted"
  default     = 0
}
