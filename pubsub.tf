module "topic_zabbix_to_pubsub" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/pubsub?ref=v29.0.0"
  project_id = var.project
  name       = "topic_zabbix_to_pubsub"
  iam = {
    "roles/pubsub.viewer"     = ["user:mgoulin@mgen.fr"]
    "roles/pubsub.publisher"  = ["serviceAccount:${google_service_account.zabbix_to_pusub.email}"]
    "roles/pubsub.subscriber" = ["user:mgoulin@mgen.fr"]
  }
}
