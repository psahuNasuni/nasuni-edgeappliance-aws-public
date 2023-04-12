##main

locals{
  instance_count=var.instance_count
}

locals{
git_repo_ui = var.use_private_ip != "Y" ? "nasuni-opensearch-userinterface-public" : "nasuni-opensearch-userinterface" 
# nasuni_edge_appliance_ami_id= var.nasuni_edge_appliance_ami_id
}

data "aws_region" current {}
data "aws_vpc" "default" {
  default = true
}

resource "random_id" "unique_appliance_id" {
  byte_length = 3
}


data "aws_vpc" "VPCtoBeUsed" {
  id = var.user_vpc_id != "" ? var.user_vpc_id : data.aws_vpc.default.id 
}

data "aws_subnet_ids" "FetchingSubnetIDs" {
  vpc_id = data.aws_vpc.VPCtoBeUsed.id
}

resource "aws_instance" "nasuni-nmc" {
  ami = var.nasuni_nmc_ami_id
  availability_zone = var.subnet_availability_zone
  instance_type = "${var.instance_type}"
  key_name = "${var.aws_key}"
  associate_public_ip_address = var.use_private_ip != "Y" ? true : false
  # associate_public_ip_address = true
  source_dest_check = false
  subnet_id = var.user_subnet_id != "" ? var.user_subnet_id : element(tolist(data.aws_subnet_ids.FetchingSubnetIDs.ids),0) 
  root_block_device {
    volume_size = var.volume_size
  }
  vpc_security_group_ids = [ var.appliance_securitygroup_id ]
  tags = {
    Name            = "nasuni-NMC-main"
    Application     = "Nasuni Analytics Connector with AWS Opensearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"

  }
  provisioner "local-exec" {
    command = "rm -rf public_nmc_ips.txt"
  }
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> public_nmc_ips.txt"
  }

}

resource "aws_instance" "nasuni-edgeappliance" {
  count = "${local.instance_count}"
  ami = var.nasuni_edge_appliance_ami_id
  availability_zone = var.subnet_availability_zone
  instance_type = "${var.instance_type}"
  key_name = "${var.aws_key}"
  associate_public_ip_address = var.use_private_ip != "Y" ? true : false
  # associate_public_ip_address = true
  source_dest_check = false
  subnet_id = var.user_subnet_id != "" ? var.user_subnet_id : element(tolist(data.aws_subnet_ids.FetchingSubnetIDs.ids),0) 
  root_block_device {
    volume_size = var.volume_size
  }
  vpc_security_group_ids = [ var.appliance_securitygroup_id ]
  tags = {
    Name            = "nasuni-edgeappliance-v${count.index}"
    Application     = "Nasuni Analytics Connector with AWS Opensearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"

  }


}

resource "local_file" "ea_ips" {
  filename = "ea_ip_addresses.txt"

  content = join("\n", aws_instance.nasuni-edgeappliance.*.public_ip)
}




############## IAM role for edge appliance vm import ######################

resource "aws_iam_role" "vmimport_access_role" {
  name        = "${var.resource_name_prefix}-vmimport_access_role-${random_id.unique_appliance_id.hex}"
  path        = "/"
  description = "Allows to perform vmimport."
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": { "Service": "vmie.amazonaws.com" },
         "Action": "sts:AssumeRole",
         "Condition": {
            "StringEquals":{
               "sts:Externalid": "vmimport"
            }
         }
      }
   ]
}
EOF
  tags = {
    Name            = "${var.resource_name_prefix}-vmimport_access_role-${random_id.unique_appliance_id.hex}"
    Application     = "Nasuni Analytics Connector with AWS Opensearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }

}

