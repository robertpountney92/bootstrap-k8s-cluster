variable "node_count" {
  default = 3
}

variable "gcp_service_list" {
  description = "List of GCP service to be enabled for a project."
  type        = list(any)
  default = [
    "compute.googleapis.com",             # Compute Engine API
    "iam.googleapis.com",                 # Identity and Access Management (IAM) API
    "cloudresourcemanager.googleapis.com" # Cloud Resource Manager API
  ]
}

variable "kubernetes_hostnames" {
  description = "List of default kubernetes hostnames"
  type        = list(any)
  default = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.svc.cluster.local"
  ]
}

variable "cluster_name" {
  default = "bootstrap-k8s-cluster"
}

variable "gcp_instance_username" {
  description = "Username used to SSH into GCP instances"
  type = string 
}

variable "private_key_location" {
  # Note: set up SSH keys to instances using `gcloud compute ssh <instance>`
  description = "Location of private key used to SSH into GCP instances"
  type = string
}

variable "country" {
  description = "Conuntry associated with TLS certificate"
  default     = "UK"
}

variable "locality" {
  description = "locality associated with TLS certificate"
  default     = "London"
}

variable "province" {
  description = "locality associated with TLS certificate"
  default     = "London"
}