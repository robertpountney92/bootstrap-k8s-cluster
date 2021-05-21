# Bootstrap etcd and Kubernetes binaries to all controller nodes
# To be perfored on all controller nodes
resource "null_resource" "bootstrap_controllers" {
  count = var.node_count
  depends_on = [
    null_resource.transfer_certs_and_keys,
    null_resource.transfer_kubeconfig_files
  ]
  triggers = {
    time = timestamp()
    # files_transferred = join(",", [
    #     null_resource.transfer_certs_and_keys[count.index].id,
    #     null_resource.transfer_kubeconfig_files[count.index].id
    #   ])
  }

  connection {
    user        = var.gcp_instance_username
    private_key = file(var.private_key_location)
    host        = google_compute_instance.k8s-controller-node-pool[count.index].network_interface.0.access_config.0.nat_ip
  }

  provisioner "file" {
    source      = "${path.module}/templates/etcd.sh"
    destination = "~/etcd.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/bootstrap-controllers.sh.tpl", {
      KUBERNETES_PUBLIC_ADDRESS = google_compute_address.k8s_static_ip_address.address
    })
    destination = "~/bootstrap-controllers.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ~/etcd.sh",
      "sudo ~/etcd.sh",
      "chmod +x ~/bootstrap-controllers.sh",
      "sudo ~/bootstrap-controllers.sh"
    ]
  }
}



# Bootstrap RBAC
# RBAC only needs to be configured on one controller node
resource "null_resource" "bootstrap_rbac" {
  depends_on = [null_resource.bootstrap_controllers]
  triggers = {
    time = timestamp()
  }

  connection {
    user        = var.gcp_instance_username
    private_key = file(var.private_key_location)
    host        = google_compute_instance.k8s-controller-node-pool[0].network_interface.0.access_config.0.nat_ip
  }

  provisioner "file" {
    source      = "${path.module}/templates/rbac.sh"
    destination = "~/rbac.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ~/rbac.sh",
      "sudo ~/rbac.sh"
    ]
  }
}