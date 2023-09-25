# Setting up the Google Cloud provider configuration
provider "google" {
  credentials = file(var.credentials)  # Update with your service account key file path
  project     = var.project_id  # Update with your Google Cloud Project ID
  region      = "YOUR_REGION"  #update with your preferred region
  zone        = "YOUR_ZONE"  # Update with the zone of your choice
}

variable credentials {}
variable project_id {}


#create a static ip
resource "google_compute_address" "my_static_ip" {
  name   = "my-static-ip-address-name" #replace with your prefered name
  region = "<YOUR_TARGET_REGION>" #replace with your preferred region
}

#fetch the created ip address
data "google_compute_address" "static_ip" {
  name = google_compute_address.my_static_ip.name
}

# Set up a firewall rule permitting incoming connections on port 443
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = "default" # Update with your network name of choice
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

   source_ranges = ["0.0.0.0/0"] # Adjust to specific IPs if tighter security is desired
  target_tags   = ["https-allow"] # Assign to VM instances tagged as
}

 # Set up an Ubuntu LTS 20.04 VM leveraging the pre-configured static IP
resource "google_compute_instance" "my_instance" {
  name         = "local-server-registry" # Update to your preferred VM instance name
  machine_type = "n1-standard-1"         # Update to your machine type of choice
  tags         = ["https-allow"]
  labels = {
    registry_server = ""
  }

  boot_disk {
  initialize_params {
    image = "ubuntu-os-cloud/ubuntu-2004-lts" # Image for Ubuntu 20.04 LTS
  }
}
# Apply the pre-configured static IP
network_interface {
  network = "default" # Specify your preferred network name
  access_config {
    nat_ip = data.google_compute_address.static_ip.name
  }
}

}

