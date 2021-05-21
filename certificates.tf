#############################################
# Bootstrap a Certificate Authority, and generate TLS certificates for: 
# etcd, kube-apiserver, kube_controller_manager, kube-scheduler, kubelet, and kube-proxy.
############################################

# Generate the CA certificate, and private key
resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca_cert" {
  key_algorithm     = "RSA"
  is_ca_certificate = true
  private_key_pem   = tls_private_key.ca_key.private_key_pem

  subject {
    common_name         = "Kubernetes"
    organization        = "Kubernetes"
    organizational_unit = "CA"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# Generate the admin client certificate and private ke
resource "tls_private_key" "admin_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "admin_csr" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.admin_key.private_key_pem

  subject {
    common_name         = "admin"
    organization        = "system:masters"
    organizational_unit = "bootstrap-k8s-cluster"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }
}

resource "tls_locally_signed_cert" "admin_cert" {
  cert_request_pem   = tls_cert_request.admin_csr.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# Generate the Kubelet client certificate and private key
resource "tls_private_key" "kubelet_key" {
  count = var.node_count

  algorithm = "RSA"
}

resource "tls_cert_request" "kubelet_csrs" {
  count = var.node_count

  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.kubelet_key[count.index].private_key_pem

  subject {
    common_name         = "system:node:${google_compute_instance.k8s-worker-node-pool[count.index].name}"
    organization        = "system:nodes"
    organizational_unit = "bootstrap-k8s-cluster"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }

  ip_addresses = [google_compute_instance.k8s-worker-node-pool[count.index].network_interface.0.network_ip, google_compute_instance.k8s-worker-node-pool[count.index].network_interface.0.access_config.0.nat_ip]
  dns_names    = [google_compute_instance.k8s-worker-node-pool[count.index].name]
}

resource "tls_locally_signed_cert" "kubelet_certs" {
  count = var.node_count

  cert_request_pem   = tls_cert_request.kubelet_csrs[count.index].cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}


# Generate the kube-controller-manager client certificate and private key
resource "tls_private_key" "kube_controller_manager_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "kube_controller_manager_csr" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.kube_controller_manager_key.private_key_pem

  subject {
    common_name         = "system:kube-controller-manager"
    organization        = "system:kube-controller-manager"
    organizational_unit = "bootstrap-k8s-cluster"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }
}

resource "tls_locally_signed_cert" "kube_controller_manager_cert" {
  cert_request_pem   = tls_cert_request.kube_controller_manager_csr.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# Generate the kube-proxy client certificate and private key
resource "tls_private_key" "kube_proxy_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "kube_proxy_csr" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.kube_proxy_key.private_key_pem

  subject {
    common_name         = "system:kube-proxy"
    organization        = "system:kube-proxy"
    organizational_unit = "bootstrap-k8s-cluster"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }
}

resource "tls_locally_signed_cert" "kube_proxy_cert" {
  cert_request_pem   = tls_cert_request.kube_proxy_csr.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# Generate the kube-scheduler client certificate and private key
resource "tls_private_key" "kube_scheduler_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "kube_scheduler_csr" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.kube_scheduler_key.private_key_pem

  subject {
    common_name         = "system:kube-scheduler"
    organization        = "system:kube-scheduler"
    organizational_unit = "bootstrap-k8s-cluster"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }
}

resource "tls_locally_signed_cert" "kube_scheduler_cert" {
  cert_request_pem   = tls_cert_request.kube_scheduler_csr.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# Generate the Kubernetes API Server certificate and private key
resource "tls_private_key" "kubernetes_api_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "kubernetes_api_csr" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.kubernetes_api_key.private_key_pem

  subject {
    common_name         = "kubernetes"
    organization        = "Kubernetes"
    organizational_unit = "bootstrap-k8s-cluster"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }

  ip_addresses = [
    google_compute_address.k8s_static_ip_address.address,
    "10.32.0.1",
    "10.240.0.10",
    "10.240.0.11",
    "127.0.0.1"
  ]

  dns_names = var.kubernetes_hostnames
}

resource "tls_locally_signed_cert" "kubernetes_api_cert" {
  cert_request_pem   = tls_cert_request.kubernetes_api_csr.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# Generate the service-account certificate and private key
resource "tls_private_key" "service_account_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "service_account_csr" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.service_account_key.private_key_pem

  subject {
    common_name         = "service-accounts"
    organization        = "Kubernetes"
    organizational_unit = "bootstrap-k8s-cluster"
    country             = var.country
    locality            = var.locality
    province            = var.province
  }
}

resource "tls_locally_signed_cert" "service_account_cert" {
  cert_request_pem   = tls_cert_request.service_account_csr.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}


# Copy the appropriate certificates and private keys to worker and controller instances
resource "null_resource" "transfer_certs_and_keys" {
  count = var.node_count

  triggers = {
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
      # Give instances a little longer to be fully ready for scp
      sleep 15

      # Store certs and keys for worker nodes locally
      echo '${tls_self_signed_cert.ca_cert.cert_pem}' > 'certs/worker/ca.pem'
      echo '${tls_private_key.kubelet_key[count.index].private_key_pem}' > 'keys/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}-key.pem'
      echo '${tls_locally_signed_cert.kubelet_certs[count.index].cert_pem}' > 'certs/worker/${google_compute_instance.k8s-worker-node-pool[count.index].name}.pem'
      echo '${tls_private_key.kube_proxy_key.private_key_pem}' > 'keys/worker/kube-proxy-key.pem'
      echo '${tls_locally_signed_cert.kube_proxy_cert.cert_pem}' > 'certs/worker/kube-proxy.pem'
      # Transfer certs and keys to worker nodes
      gcloud compute scp --recurse keys/worker/* certs/worker/* ${google_compute_instance.k8s-worker-node-pool[count.index].name}:~/ --zone=${data.google_client_config.current.zone} 
      
      # Store certs and keys for controller nodes locally
      echo '${tls_private_key.ca_key.private_key_pem}' > 'keys/controller/ca-key.pem'
      echo '${tls_self_signed_cert.ca_cert.cert_pem}' > 'certs/controller/ca.pem'
      echo '${tls_private_key.kubernetes_api_key.private_key_pem}' > 'keys/controller/kubernetes-key.pem'
      echo '${tls_locally_signed_cert.kubernetes_api_cert.cert_pem}' > 'certs/controller/kubernetes.pem'
      echo '${tls_private_key.service_account_key.private_key_pem}' > 'keys/controller/service-account-key.pem'
      echo '${tls_locally_signed_cert.service_account_cert.cert_pem}' > 'certs/controller/service-account.pem'
      echo '${tls_private_key.admin_key.private_key_pem}' > 'keys/controller/admin-key.pem'
      echo '${tls_locally_signed_cert.admin_cert.cert_pem}' > 'certs/controller/admin.pem'
      echo '${tls_private_key.kube_controller_manager_key.private_key_pem}' > 'keys/controller/kube-controller-manager-key.pem'
      echo '${tls_locally_signed_cert.kube_controller_manager_cert.cert_pem}' > 'certs/controller/kube-controller-manager.pem'
      echo '${tls_private_key.kube_scheduler_key.private_key_pem}' > 'keys/controller/kube-scheduler-key.pem'
      echo '${tls_locally_signed_cert.kube_scheduler_cert.cert_pem}' > 'certs/controller/kube-scheduler.pem'
      # Transfer certs and keys to controller nodes
      gcloud compute scp --recurse keys/controller/* certs/controller/* ${google_compute_instance.k8s-controller-node-pool[count.index].name}:~/ --zone=${data.google_client_config.current.zone} 
    EOT
  }
}