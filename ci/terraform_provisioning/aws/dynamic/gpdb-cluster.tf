variable "aws_instance-node-instance_type" {}
variable "aws_instance-node-count" {}
variable "aws_region" {}

provider "aws" {
  # Credentials are in env vars AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
  region = "${var.aws_region}"
  #  region = "us-west-2"
}

data "terraform_remote_state" "static" {
  backend = "s3"

  config {
    bucket = "gpdb5-pipeline-static-terraform"
    region = "${var.aws_region}"
    key    = "terraform.tfstate"
  }
}

resource "tls_private_key" "keypair_gen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_pet" "rand_key_name" {
  length    = 3
  prefix    = "dynamic_gpdb."
  separator = "_"
}

resource "aws_key_pair" "test_key_pair" {
  key_name   = "${random_pet.rand_key_name.id}"
  public_key = "${tls_private_key.keypair_gen.public_key_openssh}"
  depends_on = ["tls_private_key.keypair_gen"]
}

resource "aws_instance" "node" {
  count = "${var.aws_instance-node-count}"

  # TODO: look up AMI based on region => put map of regions to AMI in .tfvars file
  # If you change this, please change the default user output at the bottom.
  # Later this can be added to the logic of the proposed map
  # CentOS 6 (x86_64) - with Updates HVM AMI from us-west-2

  ami = "ami-e9503589"

  instance_type        = "${var.aws_instance-node-instance_type}"
  subnet_id            = "${data.terraform_remote_state.static.gpdb_cluster_subnet_id}"
  iam_instance_profile = "${data.terraform_remote_state.static.gpdb_cluster_profile_name}"
  security_groups      = ["${data.terraform_remote_state.static.gpdb_cluster_sg_id}"]

  # TODO: Proper key management for these boxes.
  #       Will need to consider that teams will want to ssh to boxes in order to trouble shoot.
  #       Do we need to audit the use of this key, can we use a tool to rotate as well?
  #       Also is it possible that the key is unique to a cluster, and can is stored and distributed only for the lifetime of the cluster?
  #       https://www.vaultproject.io/docs/secrets/ssh/
  key_name = "${aws_key_pair.test_key_pair.key_name}"

  root_block_device {
    volume_type = "standard"
    volume_size = "10"
    delete_on_termination = true
  }

  # We expect to use this soon.
  # ebs_block_device {
  # device_name = "/dev/xvdb"
  # volume_type = "standard"
  #   volume_size = "100"
  #   delete_on_termination = true
  # }

  tags {
    Terraform          = "true"
    Name               = "gpdb-cluster-node-${count.index}"
    hostname           = "${count.index == 0 ? "mdw" : format("sdw%d", count.index)}"
  }

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = "${tls_private_key.keypair_gen.private_key_pem}"
  }

  depends_on = ["aws_key_pair.test_key_pair"]
}

# output "ssh_string" {
#  value = ["${formatlist("ssh -i ${tls_private_key.keypair_gen.name} centos@%s",aws_instance.node.*.private_ip)}"]
# }

output "ip-addresses" {
  value = ["${aws_instance.node.*.private_ip}"]
}

output "cluster_host_list" {
  value = ["${aws_instance.node.*.tags.hostname}"]
}

output "etc_host" {
  value = ["${formatlist("%s %s %s",aws_instance.node.*.private_ip, aws_instance.node.*.tags.hostname, aws_instance.node.*.tags.Name)}"]
}

output "cluster_private_key_pem" {
  value = "${tls_private_key.keypair_gen.private_key_pem}"
}

output "cluster_public_key_openssh" {
  value = "${tls_private_key.keypair_gen.public_key_openssh}"
}

output "cluster_public_key_pem" {
  value = "${tls_private_key.keypair_gen.public_key_pem}"
}

output "ami_default_user" {
  value = "centos"
}
