# Controller Nodes
resource "google_compute_instance" "k8s-controller-node-pool" {
  count = var.node_count
  depends_on = [
    google_project_service.gcp_services
  ]

  name           = "controller-${count.index}"
  machine_type   = "e2-standard-2"
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_vpc_network.name
    subnetwork = google_compute_subnetwork.k8s_subnetwork.name
    network_ip = "10.240.0.1${count.index}"
    access_config {
      // Ephemeral IP
    }
  }
  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata_startup_script = "echo hi > /test.txt"
  tags                    = ["bootstrap-k8s-cluster", "controller"]
}

# Worker Nodes
resource "google_compute_instance" "k8s-worker-node-pool" {
  count = var.node_count
  depends_on = [
    google_project_service.gcp_services
  ]

  name           = "worker-${count.index}"
  machine_type   = "e2-standard-2"
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_vpc_network.name
    subnetwork = google_compute_subnetwork.k8s_subnetwork.name
    network_ip = "10.240.0.2${count.index}"

    access_config {
      // Ephemeral IP
    }
  }
  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    pod-cidr = "10.200.${count.index}.0/24"
  }
  metadata_startup_script = "echo hi > /test.txt"
  tags                    = ["bootstrap-k8s-cluster", "worker"]
}



