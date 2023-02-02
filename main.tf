
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
    command = var.use_private_ip != "Y" ? "echo ${aws_instance.nasuni-edgeappliance.public_ip} > nasuni-edgeappliance_IP.txt" : "echo ${aws_instance.nasuni-edgeappliance.private_ip} > nasuni-edgeappliance_IP.txt"
  }
  depends_on = [aws_instance.nasuni-edgeappliance]
}

#  resource "null_resource" "Inatall_Packages" {
#  provisioner "remote-exec" {
#     inline = [
#       "echo '@@@@@@@@@@@@@@@@@@@@@ STARTED - Inastall Packages @@@@@@@@@@@@@@@@@@@@@@@'",
#       "sudo apt update",
#       "sudo apt upgrade -y",
#       "sudo apt install dos2unix -y",
#       "sudo apt install curl bash ca-certificates git openssl wget vim -y",
#       "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
#       "sudo apt-add-repository \"deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
#       "sudo apt update",
#       "sudo apt install terraform",
#       "terraform -v",
#       "which terraform",
#       "sudo apt install jq -y",
#       "sudo apt install zip -y",
#       "sudo apt install unzip -y",
#       "sudo apt install python3.9 -y",
#       "sudo apt install python3-pip -y",
#       "alias python3='/usr/bin/python3.9'",
#       "alias pip3='python3.9 -m pip'",
#       "sudo pip3 install boto3",
#       "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
#       "sudo unzip awscliv2.zip",
#       "sudo ./aws/install",
#       "aws --version",
#       "which aws",
#       "echo '@@@@@@@@@@@@@@@@@@@@@ FINISHED - Inastall Packages @@@@@@@@@@@@@@@@@@@@@@@'"
#       ]
#   }

#   connection {
#     type        = "ssh"
#     host = var.use_private_ip != "Y" ? aws_instance.nasuni-edgeappliance.public_ip : aws_instance.nasuni-edgeappliance.private_ip
#     user        = "ubuntu"
#     private_key = file("./${var.pem_key_file}")
#   }
#  }



# resource "null_resource" "cleanup_temp_files" {
#    provisioner "local-exec" {
#     command = "echo . > awacck.txt && echo . > awsecck.txt"
#   }
#    provisioner "local-exec" {
#     when    = destroy
#     command = "rm -rf *cck.txt"
#   }
# }

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