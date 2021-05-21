provider "google" {
  # Set env variable GOOGLE_APPLICATION_CREDENTIALS, GOOGLE_PROJECT, GOOGLE_REGION, GOOGLE_ZONE
}

# Access the configuration of the Google Cloud provider
data "google_client_config" "current" {}