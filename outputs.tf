output "kubernetes_public_ip_address" {
  value = google_compute_address.k8s_static_ip_address.address
}