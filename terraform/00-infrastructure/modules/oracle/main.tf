terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.18.0"
    }
  }
}

variable "tenancy_ocid" {
  type = string
  default = "ocid1.tenancy.oc1..aaaaaaaaamup363q6nms526umcphqshjk6iy3jlqkwt26foyu2nf7lrcfvxa"
}

variable "user_ocid" {
  type = string 
  default = "ocid1.user.oc1..aaaaaaaabpp4hp6h6a4dl4yhcjkfmr6scugto2wm3wdyhxscmgp4ih3dvyta"
}

variable "private_key_path" {
  type = string
  default = "~/.oci/brandonros1@gmail.com_2024-11-24T01_30_06.889Z.pem"
}

variable "fingerprint" {
  type = string
  default = "1a:46:5f:55:57:29:11:91:3c:64:0a:ba:7c:39:29:91"
}

variable "region" {
  type = string
  default = "us-ashburn-1"
}

variable "availability_domain" {
  type    = string
  default = "xYGb:US-ASHBURN-AD-3"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

# Get a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get the latest Oracle Linux image
data "oci_core_images" "ubuntu" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create a VCN
resource "oci_core_vcn" "free_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.tenancy_ocid
  display_name   = "free-vcn"
  dns_label      = "freevcn"
}

# Create internet gateway
resource "oci_core_internet_gateway" "free_ig" {
  compartment_id = var.tenancy_ocid
  display_name   = "free-internet-gateway"
  vcn_id         = oci_core_vcn.free_vcn.id
}

# Create route table
resource "oci_core_route_table" "free_rt" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.free_vcn.id
  display_name   = "free-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.free_ig.id
  }
}

# Create a subnet
resource "oci_core_subnet" "free_subnet" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.tenancy_ocid
  vcn_id            = oci_core_vcn.free_vcn.id
  route_table_id    = oci_core_route_table.free_rt.id
  security_list_ids = [oci_core_vcn.free_vcn.default_security_list_id]
  display_name      = "free-subnet"
}

# Create an instance
resource "oci_core_instance" "free_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.tenancy_ocid
  display_name        = "free-instance"
  shape               = "VM.Standard.E2.1.Micro" # AMD EPYC 7551, dictated by the free tier
  #shape               = "VM.Standard.A1.Flex" # ARM-based shape for Always Free tier (out of capacity)

  shape_config {
    memory_in_gbs = 1 # dictated by the free tier
    ocpus         = 1 # dictated by the free tier
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.free_subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = "${file("~/.ssh/id_rsa.pub")}"
  }
}

output "instance_username" {
  value = "ubuntu"  # Default username for Ubuntu instances in OCI
}

output "instance_ipv4" {
  value = oci_core_instance.free_instance.public_ip
}

output "ssh_port" {
  value = 22
}
