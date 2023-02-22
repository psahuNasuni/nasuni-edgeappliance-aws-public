
##main
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

resource "aws_instance" "nasuni-edgeappliance" {
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
    Name            = var.nasuni_edge_appliance_name
    Application     = "Nasuni Analytics Connector with AWS Opensearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"

  }

}

# resource "null_resource" "update_secGrp" {
#   provisioner "local-exec" {
#      command = "sh update_secGrp.sh ${aws_instance.nasuni-edgeappliance.public_ip} ${var.nasuni_edge_appliance_name} ${data.aws_region.current.name} ${var.aws_profile} "
#   }
#   depends_on = [aws_instance.nasuni-edgeappliance]
# }

resource "null_resource" "nasuni-edgeappliance_IP" {
  provisioner "local-exec" {
    command =var.use_private_ip != "Y" ? "echo ${aws_instance.nasuni-edgeappliance.public_ip} > nasuni-edgeappliance_IP.txt" : "echo ${aws_instance.nasuni-edgeappliance.private_ip} > nasuni-edgeappliance_IP.txt"
	}
provisioner "local-exec"{
    command = "sed -i 's#$EdgeApplianceIpAddress.*$#$EdgeApplianceIpAddress = \"${aws_instance.nasuni-edgeappliance.public_ip}\"#g' Variables.ps1"
}
provisioner "local-exec" {
    command = "sleep 150"
  }
}

resource "null_resource" "ShellScript" {
  provisioner "local-exec" {
    command = "psupgrade.sh"
    interpreter = ["sh", "-Command"]
  }
}

resource "null_resource" "PowerShellScript" {
  provisioner "local-exec" {
    command = "pwsh AutodeployEA.ps1 Variables.ps1"
    interpreter = ["pwsh", "-Command"]
  }
  depends_on = [null_resource.nasuni-edgeappliance_IP]
}

locals {
  nasuni-edgeappliance-IP = var.use_private_ip != "Y" ? aws_instance.nasuni-edgeappliance.public_ip : aws_instance.nasuni-edgeappliance.private_ip
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

