data "aws_ami" "my_ami" {
  owners      = var.ami_owner
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

locals {
  # Use user-defined subnets first if they are set, otherwise use dad subnets
  subnets = coalescelist(
    var.subnets,
    module.common.dad_subnet_ids.internal,
  )
  ami_id_local   = coalesce(var.ami_id, data.aws_ami.my_ami.image_id)
  iam_name_local = "${var.name}_ec2_role"

  common_tags = {
    Environment                                     = var.env != "" ? var.env : null
    melody-ssm-managed-scan                        = "true"
    melody-ssm-managed-crowdstrike-install-linux   = data.aws_ami.my_ami.platform != "Windows" ? var.dad_crowdstrike_install : null # platform will be Windows for Windows AMIs; otherwise blank
    melody-ssm-managed-crowdstrike-install-windows = data.aws_ami.my_ami.platform == "Windows" ? var.dad_crowdstrike_install : null # platform will be Windows for Windows AMIs; otherwise blank
    "melody:ssm:managed-qualys-install-linux"      = data.aws_ami.my_ami.platform != "Windows" ? var.dad_qualys_install : null      # platform will be Windows for Windows AMIs; otherwise blank
  }

  tags = merge(var.tags, local.common_tags)
}

data "aws_subnet" "selected" {
  id = local.subnets[0]
}

data "aws_vpc" "ec2_vpc" {
  id = data.aws_subnet.selected.vpc_id
}

data "aws_kms_key" "kms_key" {
  key_id = var.kms_key_id
}

######
# Note: network_interface can't be specified together with associate_public_ip_address
######

resource "aws_instance" "ec2_instance" {
  count                       = var.instance_count
  ami                         = local.ami_id_local
  instance_type               = var.instance_type
  user_data                   = var.user_data
  subnet_id                   = local.subnets[count.index % length(local.subnets)]
  monitoring                  = var.monitoring
  vpc_security_group_ids      = var.create_security_group ? [aws_security_group.ec2_instance[0].id] : null
  iam_instance_profile        = coalesce(var.iam_name, alks_iamrole.ec2_role.name)
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = length(var.private_ip) > count.index ? element(var.private_ip, count.index) : null
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses
  ebs_optimized               = var.ebs_optimized
  volume_tags                 = var.volume_tags
  key_name                    = var.key_pair_name

  root_block_device {
    volume_type = var.root_block_device_type
    volume_size = var.root_block_device_size
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }
  source_dest_check                    = var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy
  tags = merge(
    {
      "Name" = var.instance_count > 1 || var.use_num_suffix == "true" ? format("%s-%d", var.name, count.index + 1) : var.name
    },
    local.tags,
  )
}

resource "aws_ebs_volume" "data_disk" {
  count             = var.instance_count * length(var.ebs_device_list) * var.ebs_required
  availability_zone = aws_instance.ec2_instance[floor(count.index / length(var.ebs_device_list))].availability_zone
  size              = var.ebs_size
  type              = var.ebs_type
  encrypted         = var.ebs_encrypted
  kms_key_id        = data.aws_kms_key.kms_key.arn
}

resource "aws_volume_attachment" "data-volume-attachment" {
  count        = var.instance_count * length(var.ebs_device_list) * var.ebs_required
  device_name  = var.ebs_device_list[count.index % length(var.ebs_device_list)]
  instance_id  = aws_instance.ec2_instance[floor(count.index / length(var.ebs_device_list))].id
  volume_id    = aws_ebs_volume.data_disk[count.index].id
  skip_destroy = var.ebs_skip_destroy
  force_detach = var.ebs_force_detach
}

resource "aws_security_group" "ec2_instance" {
  count  = var.create_security_group ? 1 : 0
  vpc_id = data.aws_subnet.selected.vpc_id
}

resource "aws_security_group_rule" "ingress_security_group_ec2" {
  count = var.create_security_group && length(var.security_group_ingress_list) > 0 ? length(var.security_group_ingress_list) : 0

  security_group_id = aws_security_group.ec2_instance[0].id
  type              = "ingress"
  from_port         = var.security_group_ingress_list[count.index]["from_port"]
  to_port           = var.security_group_ingress_list[count.index]["to_port"]
  protocol          = var.security_group_ingress_list[count.index]["protocol"]
  cidr_blocks = [coalesce(
    lookup(var.security_group_ingress_list[count.index], "cidr_blocks", null),
    data.aws_vpc.ec2_vpc.cidr_block,
  )]
}

resource "aws_security_group_rule" "egress_security_group_ec2" {
  count = var.create_security_group && length(var.security_group_egress_list) > 0 ? length(var.security_group_egress_list) : 0

  security_group_id = aws_security_group.ec2_instance[0].id
  type              = "egress"
  from_port         = var.security_group_egress_list[count.index]["from_port"]
  to_port           = var.security_group_egress_list[count.index]["to_port"]
  protocol          = var.security_group_egress_list[count.index]["protocol"]
  cidr_blocks = [coalesce(
    lookup(var.security_group_egress_list[count.index], "cidr_blocks", null),
    data.aws_vpc.ec2_vpc.cidr_block,
  )]
}

resource "alks_iamrole" "ec2_role" {
  name_prefix              = coalesce(var.iam_name, local.iam_name_local)
  type                     = "Amazon EC2"
  include_default_policies = false
}

resource "aws_iam_policy" "default_policy" {
  name_prefix = "default-"
  path        = "/acct-managed/"
  description = "xyz default EC2 policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutRetentionPolicy"
      ],
      "Resource": "arn:aws:logs:${var.tf_region}:${module.common.account_id}:log-group:/xyz/systemlogs/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "default_policy_attachment" {
  role       = alks_iamrole.ec2_role.id
  policy_arn = aws_iam_policy.default_policy.arn
}

resource "aws_iam_role_policy" "ec2_policy" {
  count  = length(var.policy_list)
  name   = var.policy_list[count.index]["name"]
  role   = alks_iamrole.ec2_role.id
  policy = file(var.policy_list[count.index]["policy"])
}

resource "aws_iam_role_policy" "ec2_policy_text" {
  count  = length(var.policies)
  name   = format("%s-policy%d", var.name, count.index + 1)
  role   = alks_iamrole.ec2_role.id
  policy = var.policies[count.index]
}

resource "aws_iam_role_policy_attachment" "attach_existing_policies" {
  count      = length(var.attach_existing_policy_list)
  role       = alks_iamrole.ec2_role.id
  policy_arn = var.attach_existing_policy_list[count.index]
}
