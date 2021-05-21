# Static IP address attached to the external load balancer fronting the K8s API Servers
resource "google_compute_address" "k8s_static_ip_address" {
  name = "bootstrap-k8s-public-ip-address"
}