

# allow all access from IAP and health check ranges
resource "google_compute_firewall" "fw-vault" {
  name          = "server-vault"
  direction     = "INGRESS"
  network       = data.google_compute_network.vpc.self_link
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = [8200]
  }
}
# export VAULT_ADDR=https://34.163.44.202:8200
# export VAULT_TOKEN=*********************
# export VAULT_SKIP_VERIFY=true
# vault secrets enable gcp
# vault write gcp/config credentials=@credentials.json
# vault write gcp/static-account/zabbix-token-account \
#    service_account_email="zabbix-token@sandbox-mgoulin.iam.gserviceaccount.com" \
#    secret_type="access_token"  \
#    token_scopes="https://www.googleapis.com/auth/cloud-platform"
# vault read gcp/static-account/zabbix-token-account/token
# ********************************
# 
module "vault_server" {
  source        = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/compute-vm?ref=v29.0.0"
  project_id    = var.project
  zone          = var.zone
  name          = "vault-server"
  instance_type = "e2-medium"
  boot_disk = {
    use_independent_disk = true
    initialize_params = {
      image = "projects/debian-cloud/global/images/debian-11-bullseye-v20240312"
      type  = "pd-ssd"
      size  = 20
    }
  }
  network_interfaces = [{
    network    = data.google_compute_network.vpc.self_link
    subnetwork = data.google_compute_subnetwork.subnet.self_link
    nat        = true
    addresses  = {}
  }]
  tags = ["ssh", "vault-server", "https-server", "http-server"]
  attached_disks = [
    {
      name = "vault-db-data"
      size = 50
    }
  ]
  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
      sudo apt update && sudo apt install vault
      sudo systemctl start vault
    EOF
  }
  service_account = {
    auto_create = true
  }
}
