# image
#data "google_compute_image" "image" {
#  family  = "zabbix-appliance-6-4"
#  project = "zabbix-public"
#}

# 
module "zabbix_server" {
  source        = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/compute-vm?ref=v29.0.0"
  project_id    = var.project
  zone          = var.zone
  name          = "zabbix-server"
  instance_type = "e2-medium"
  boot_disk = {
    use_independent_disk = true
    initialize_params = {
      image = "projects/zabbix-public/global/images/zabbix-appliance-6-4"
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
  tags = ["ssh", "https-server", "http-server"]
  attached_disks = [
    {
      name = "zabbix-server-db-data"
      size = 50
    }
  ]
  metadata = {
    zabbix-web     = var.project
    appliance-name = var.project
    startup-script = <<-EOF
      #! /bin/bash
      /000-datadisk && /001-zabbix && echo StartConnectors=5 >> /etc/zabbix/zabbix_server.conf && systemctl restart zabbix-server && rm /000-datadisk && rm /001-zabbix && touch /tmp/success.log
    EOF
  }
  service_account = {
    auto_create = true
  }
}
# tftest modules=1 resources=1 inventory=defaults.yaml
