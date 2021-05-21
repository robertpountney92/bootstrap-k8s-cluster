# Bootstrap worker nodes with runc, container networking plugins, containerd, kubelet and kube-proxy.
# To be perfored on all worker nodes
resource "null_resource" "bootstrap_workers" {
  count = var.node_count
  depends_on = [
    null_resource.bootstrap_rbac,
  ]
  triggers = {
    time = timestamp()
  }

  connection {
    user        = var.gcp_instance_username
    private_key = file(var.private_key_location)
    host        = google_compute_instance.k8s-worker-node-pool[count.index].network_interface.0.access_config.0.nat_ip
  }

  provisioner "file" {
    source      = "${path.module}/templates/bootstrap-workers.sh"
    destination = "~/bootstrap-workers.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ~/bootstrap-workers.sh",
      "sudo ~/bootstrap-workers.sh"
    ]
  }
}