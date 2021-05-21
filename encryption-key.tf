# Copy the encyption key to controller nodes
resource "null_resource" "transfer_encyption_key" {
  count = var.node_count
  depends_on = [ 
    null_resource.transfer_certs_and_keys, 
    null_resource.transfer_kubeconfig_files 
  ]
  triggers = {
    time = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
cat > encryption-config/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
          - name: key1
            secret: $(head -c 32 /dev/urandom | base64)
    - identity: {}
EOF
gcloud compute scp encryption-config/encryption-config.yaml ${google_compute_instance.k8s-controller-node-pool[count.index].name}:~/ --zone=${data.google_client_config.current.zone}   
    EOT
  }
}