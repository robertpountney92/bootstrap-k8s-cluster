# Copy the appropriate kubeconfig files to worker and controller nodes
resource "null_resource" "transfer_kubeconfig_files" {
  count = var.node_count
  depends_on = [ null_resource.transfer_certs_and_keys ]
  triggers = {
    # This will need to be changed, bettter to check if change to any resources 
    # Should concatenate all resources together with join() command and "," to check the diff
    time = timestamp()
    # all_certs = join(",", [
    #     tls_private_key.ca_key.private_key_pem,
    #     tls_self_signed_cert.ca_cert.cert_pem,
    #     tls_private_key.kubelet_key[count.index].private_key_pem,
    #     tls_locally_signed_cert.kubelet_certs[count.index].cert_pem,
    #     tls_private_key.kube_proxy_key.private_key_pem,
    #     tls_locally_signed_cert.kube_proxy_cert.cert_pem,
    #     tls_private_key.kubernetes_api_key.private_key_pem,
    #     tls_locally_signed_cert.kubernetes_api_cert.cert_pem,
    #     tls_private_key.service_account_key.private_key_pem,
    #     tls_locally_signed_cert.service_account_cert.cert_pem,
    #     tls_private_key.admin_key.private_key_pem,
    #     tls_locally_signed_cert.admin_cert.cert_pem,
    #     tls_private_key.kube_controller_manager_key.private_key_pem,
    #     tls_locally_signed_cert.kube_controller_manager_cert.cert_pem,
    #     tls_private_key.kube_scheduler_key.private_key_pem,
    #     tls_locally_signed_cert.kube_scheduler_cert.cert_pem   
    #   ])
  }

  provisioner "local-exec" {
    command = <<EOT
      #####################################
      # Worker nodes kubeconfig files #
      #####################################

      # Hacky fix, TF attempts to configure kubeconfig files for all workers at once
      # this is not possible and produces a ".kube/config.lock: file exists" error
      # To fix, I stagger the configurations so they don't conflict
      if [ ${count.index} -gt 0 ]; then
        echo "Count index is ${count.index} sleeping for $((${count.index}*5)) seconds..."
        sleep $((${count.index}*5))
      fi

      # kubelet
      kubectl config set-cluster ${var.cluster_name} \
        --certificate-authority=certs/worker/ca.pem \
        --embed-certs=true \
        --server=https://${google_compute_address.k8s_static_ip_address.address}:6443 \
        --kubeconfig=kubeconfigs/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}.kubeconfig
      kubectl config set-credentials system:node:${google_compute_instance.k8s-worker-node-pool[count.index].name} \
        --client-certificate=certs/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}.pem \
        --client-key=keys/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}-key.pem \
        --embed-certs=true \
        --kubeconfig=kubeconfigs/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}.kubeconfig
      kubectl config set-context default \
        --cluster=${var.cluster_name} \
        --user=system:node:${google_compute_instance.k8s-worker-node-pool[count.index].name} \
        --kubeconfig=kubeconfigs/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}.kubeconfig
      kubectl config use-context default --kubeconfig=kubeconfigs/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}.kubeconfig  
      
      # kube-proxy
      kubectl config set-cluster ${var.cluster_name} \
        --certificate-authority=certs/worker/ca.pem \
        --embed-certs=true \
        --server=https://${google_compute_address.k8s_static_ip_address.address}:6443 \
        --kubeconfig=kubeconfigs/worker/kube-proxy.kubeconfig
      kubectl config set-credentials system:kube-proxy \
        --client-certificate=certs/worker/kube-proxy.pem \
        --client-key=keys/worker/kube-proxy-key.pem \
        --embed-certs=true \
        --kubeconfig=kubeconfigs/worker/kube-proxy.kubeconfig
      kubectl config set-context default \
        --cluster=${var.cluster_name} \
        --user=system:kube-proxy \
        --kubeconfig=kubeconfigs/worker/kube-proxy.kubeconfig
      kubectl config use-context default --kubeconfig=kubeconfigs/worker/kube-proxy.kubeconfig

      # Hacky fix, TF it is attempts to configure both config files worker-1/2 
      # at the same time, this is not possible and produces a .kube/config.lock: file exists error
      # To fix just configure the cluster again later to avoid lock.
      kubectl config set-cluster ${var.cluster_name} \
        --certificate-authority=certs/worker/ca.pem \
        --embed-certs=true \
        --server=https://${google_compute_address.k8s_static_ip_address.address}:6443 \
        --kubeconfig=kubeconfigs/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}.kubeconfig

      # Transfer kubeconfig files to worker nodes
      gcloud compute scp --recurse kubeconfigs/worker/* ${google_compute_instance.k8s-worker-node-pool[count.index].name}:~/ --zone=${data.google_client_config.current.zone} 
    
      #####################################
      # Controller nodes kubeconfig files #
      #####################################
      # kube-controller
      kubectl config set-cluster ${var.cluster_name} \
        --certificate-authority=certs/controller/ca.pem \
        --embed-certs=true \
        --server=https://127.0.0.1:6443 \
        --kubeconfig=kubeconfigs/controller/kube-controller-manager.kubeconfig
      kubectl config set-credentials system:kube-controller-manager \
        --client-certificate=certs/controller/kube-controller-manager.pem \
        --client-key=keys/controller/kube-controller-manager-key.pem \
        --embed-certs=true \
        --kubeconfig=kubeconfigs/controller/kube-controller-manager.kubeconfig
      kubectl config set-context default \
        --cluster=${var.cluster_name} \
        --user=system:kube-controller-manager \
        --kubeconfig=kubeconfigs/controller/kube-controller-manager.kubeconfig
      kubectl config use-context default --kubeconfig=kubeconfigs/controller/kube-controller-manager.kubeconfig
      
      # kube-scheduler
      kubectl config set-cluster ${var.cluster_name} \
        --certificate-authority=certs/controller/ca.pem \
        --embed-certs=true \
        --server=https://127.0.0.1:6443 \
        --kubeconfig=kubeconfigs/controller/kube-scheduler.kubeconfig
      kubectl config set-credentials system:kube-scheduler \
        --client-certificate=certs/controller/kube-scheduler.pem \
        --client-key=keys/controller/kube-scheduler-key.pem \
        --embed-certs=true \
        --kubeconfig=kubeconfigs/controller/kube-scheduler.kubeconfig
      kubectl config set-context default \
        --cluster=${var.cluster_name} \
        --user=system:kube-scheduler \
        --kubeconfig=kubeconfigs/controller/kube-scheduler.kubeconfig
      kubectl config use-context default --kubeconfig=kubeconfigs/controller/kube-scheduler.kubeconfig
      
      # admin
      kubectl config set-cluster ${var.cluster_name} \
        --certificate-authority=certs/controller/ca.pem \
        --embed-certs=true \
        --server=https://127.0.0.1:6443 \
        --kubeconfig=kubeconfigs/controller/admin.kubeconfig
      kubectl config set-credentials admin \
        --client-certificate=certs/controller/admin.pem \
        --client-key=keys/controller/admin-key.pem \
        --embed-certs=true \
        --kubeconfig=kubeconfigs/controller/admin.kubeconfig
      kubectl config set-context default \
        --cluster=${var.cluster_name} \
        --user=admin \
        --kubeconfig=kubeconfigs/controller/admin.kubeconfig
      kubectl config use-context default --kubeconfig=kubeconfigs/controller/admin.kubeconfig

      # Transfer kubeconfig files to controller nodes
      gcloud compute scp --recurse kubeconfigs/controller/* ${google_compute_instance.k8s-controller-node-pool[count.index].name}:~/ --zone=${data.google_client_config.current.zone}     
    EOT
  }
}