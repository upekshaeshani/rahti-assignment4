terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}

# --------------------------------------------------
# Existing project network
# --------------------------------------------------

data "openstack_networking_network_v2" "project_network" {
  name = var.network_name
}

# --------------------------------------------------
# Ubuntu image
# --------------------------------------------------

data "openstack_images_image_v2" "ubuntu" {
  name = var.image_name
}

# --------------------------------------------------
# SSH key pair
# --------------------------------------------------

resource "openstack_compute_keypair_v2" "week7_key" {
  name       = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
}

# --------------------------------------------------
# Security group
# --------------------------------------------------

resource "openstack_networking_secgroup_v2" "web_sg" {
  name        = "week7-web-sg"
  description = "Security group for Week 7 web server"
}

# Allow HTTP from anywhere
resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

# Allow SSH only from my IP
resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.ssh_allowed_cidr
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

# --------------------------------------------------
# Web server VM
# --------------------------------------------------

resource "openstack_compute_instance_v2" "web" {
  name            = var.vm_name
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_name     = var.flavor_name
  key_pair        = openstack_compute_keypair_v2.week7_key.name
  security_groups = [openstack_networking_secgroup_v2.web_sg.name]

  network {
    uuid = data.openstack_networking_network_v2.project_network.id
  }

  # Install and configure Apache using cloud-init
  user_data = file("${path.module}/cloud-init.yaml")
}

# --------------------------------------------------
# Find the network port created for the VM
# --------------------------------------------------

data "openstack_networking_port_v2" "web_port" {
  device_id  = openstack_compute_instance_v2.web.id
  network_id = data.openstack_networking_network_v2.project_network.id
}

# --------------------------------------------------
# External/public network
# --------------------------------------------------

data "openstack_networking_network_v2" "external" {
  name     = var.external_network_name
  external = true
}

# --------------------------------------------------
# Floating/public IP
# --------------------------------------------------

resource "openstack_networking_floatingip_v2" "web_ip" {
  pool = data.openstack_networking_network_v2.external.name
}

# --------------------------------------------------
# Attach floating IP to VM's network port
# --------------------------------------------------

resource "openstack_networking_floatingip_associate_v2" "web_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.web_ip.address
  port_id     = data.openstack_networking_port_v2.web_port.id
}