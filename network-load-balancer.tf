resource "google_compute_http_health_check" "kubernetes" {
  name         = "kubernetes-health-check"
  request_path = "/healthz"
  host         = "kubernetes.default.svc.cluster.local"
}


resource "google_compute_firewall" "kubernetes-allow-health-check" {
  name    = "bootstrap-k8s-allow-health-check"
  network = google_compute_network.k8s_vpc_network.name

  allow {
    protocol = "tcp"
  }

  source_ranges = ["209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]
}


resource "google_compute_target_pool" "kubernetes-target-pool" {
  name = "instance-pool"

  instances = google_compute_instance.k8s-controller-node-pool[*].self_link

  health_checks = [
    google_compute_http_health_check.kubernetes.name,
  ]
}

resource "google_compute_forwarding_rule" "kubernetes-forwarding-rule" {
  name       = "bootstrap-k8s-forwarding-rule"
  region     = data.google_client_config.current.region
  port_range = 6443
  ip_address = google_compute_address.k8s_static_ip_address.address
  target     = google_compute_target_pool.kubernetes-target-pool.id
}