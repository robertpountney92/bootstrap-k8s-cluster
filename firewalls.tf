# Firewall rule that allows internal communication across all protocols
resource "google_compute_firewall" "kubernetes-allow-internal" {
  name    = "bootstrap-k8s-allow-internal-firewall"
  network = google_compute_network.k8s_vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]

}

# Firewall rule that allows external SSH, ICMP, and HTTPS
resource "google_compute_firewall" "kubernetes-allow-external" {
  name    = "bootstrap-k8s-allow-external-firewall"
  network = google_compute_network.k8s_vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]

}