# Dedicated VPC network to host the K8s cluster
resource "google_compute_network" "k8s_vpc_network" {
  name                    = "bootstrap-k8s-vpc-network"
  auto_create_subnetworks = false
}

# Subnet provisioned with a large IP range to assign a private IP to each node in the K8s cluster
resource "google_compute_subnetwork" "k8s_subnetwork" {
  name          = "bootstrap-k8s-subnetwork"
  ip_cidr_range = "10.240.0.0/24"
  network       = google_compute_network.k8s_vpc_network.id
}

resource "google_compute_route" "k8s_route" {
  count       = var.node_count

  name        = "kubernetes-route-10-200-${count.index}-0-24" 
  network     = google_compute_network.k8s_vpc_network.name
  next_hop_instance = google_compute_instance.k8s-worker-node-pool[count.index].self_link
  dest_range  = "10.200.${count.index}.0/24"
}