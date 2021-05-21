# bootstrap-k8s-cluster

This repository automates the bootstraping of a Kubernetes cluster from scratch using Terraform.


## Prerequisites 
- Install `gcloud` CLI 
- Install `terraform` 
- Install `kubectl`


## Create Project and Service Account in Google Cloud

Create new project

    export PROJECT_ID=bootstrap-k8s-cluster
    gcloud projects create $PROJECT_ID
    gcloud config set project $PROJECT_ID # Set project id as current

Create service account (to manage resources via Terraform)

    export SERVICE_ACCOUNT_ID=bootstrap-k8s-cluster-sa
    gcloud iam service-accounts create $SERVICE_ACCOUNT_ID
    
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_ID@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/owner"
    
    export KEY_FILE=~/gcloud-sa-keys/bootstrap-k8s-cluster-key-file.json
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SERVICE_ACCOUNT_ID@$PROJECT_ID.iam.gserviceaccount.com

## Create Kubernetes cluster using Terraform

Set environment variables `GOOGLE_APPLICATION_CREDENTIALS, GOOGLE_PROJECT, GOOGLE_REGION, GOOGLE_ZONE`

    terraform init
    terraform apply -auto-approve

## Configuring kubectl for remote access

    export KUBERNETES_PUBLIC_ADDRESS=$(terraform output kubernetes_public_ip_address | jq -r)

    kubectl config set-cluster bootstrap-k8s-cluster \
    --certificate-authority=certs/controller/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

    kubectl config set-credentials admin \
    --client-certificate=certs/controller/admin.pem \
    --client-key=keys/controller/admin-key.pem

    kubectl config set-context bootstrap-k8s-cluster \
    --cluster=bootstrap-k8s-cluster \
    --user=admin

    kubectl config use-context bootstrap-k8s-cluster


## Deploying the DNS Cluster Add-on
Deploy the coredns cluster add-on for service discovery

    kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml

List the pods created by the kube-dns deployment
  
    kubectl get pods -l k8s-app=kube-dns -n kube-system


## Verify the cluster is working

### Pods

Create a pod

    kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

List the pod created by the busybox deployment:

    kubectl get pods -l run=busybox


### Secrets

Create a generic secret

    kubectl create secret generic bootstrap-k8s-cluster \
        --from-literal="mykey=mydata"

Print a hexdump of the bootstrap-k8s-cluster secret stored in etcd:

    gcloud compute ssh controller-0 \
    --command "sudo ETCDCTL_API=3 etcdctl get \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.pem \
    --cert=/etc/etcd/kubernetes.pem \
    --key=/etc/etcd/kubernetes-key.pem\
    /registry/secrets/default/bootstrap-k8s-cluster | hexdump -C"
    output


### Deployments

Create a deployment for the nginx web server:

    kubectl create deployment nginx --image=nginx

List the pod created by the nginx deployment:

    kubectl get pods -l app=nginx

### Port Forwarding

Access applications remotely using port forwarding.

Retrieve the full name of the nginx pod:

    POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")

Forward port 8080 on your local machine to port 80 of the nginx pod:

    kubectl port-forward $POD_NAME 8080:80

Navigate to `127.0.0.1` in your browser to see default nginx page.

### Logs

Print the nginx pod logs:

    kubectl logs $POD_NAME

Print the nginx version by executing the nginx -v command in the nginx container:

    kubectl exec -ti $POD_NAME -- nginx -v

### Services

Expose the nginx deployment using a NodePort service:

    kubectl expose deployment nginx --port 80 --type NodePort

Retrieve the node port assigned to the nginx service:

    NODE_PORT=$(kubectl get svc nginx \
    --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
    
Create a firewall rule that allows remote access to the nginx node port:

    gcloud compute firewall-rules create bootstrap-k8s-cluster-allow-nginx-service \
    --allow=tcp:${NODE_PORT} \
    --network bootstrap-k8s-vpc-network

Retrieve the external IP address of a worker instance:

    EXTERNAL_IP=$(gcloud compute instances describe worker-0 \
    --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

Make an HTTP request using the external IP address and the nginx node port:

    curl -I http://${EXTERNAL_IP}:${NODE_PORT}

## Clean up

If you created firewall rule via `gcloud`

    gcloud compute firewall-rules delete bootstrap-k8s-cluster-allow-nginx-service -q

Clean up resources managed by `Terraform`

    terraform destroy -auto-approve