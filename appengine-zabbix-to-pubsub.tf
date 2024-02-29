resource "google_service_account" "zabbix_to_pusub" {
  account_id = "zabbix-to-pubsub-appengine"
}

resource "random_id" "zabbix_to_pusub" {
  byte_length = 8
}
resource "google_storage_bucket" "zabbix_to_pusub" {
  name                        = "zabbix-to-pubsub-appengine-static-content-${random_id.zabbix_to_pusub.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
}

resource "google_project_service_identity" "cloudbuild_sa" {
  provider = google-beta

  project = data.google_project.project.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_storage_bucket_iam_member" "zabbix_to_pusub" {
  bucket = google_storage_bucket.zabbix_to_pusub.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_project_service_identity.cloudbuild_sa.email}"
}
resource "google_project_iam_member" "zabbix_to_pusub" {
  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_project_service_identity.cloudbuild_sa.email}"
}


resource "google_storage_bucket_object" "zabbix_to_pusub" {
  for_each = fileset("${path.module}/code", "*")

  name   = each.key
  bucket = google_storage_bucket.zabbix_to_pusub.name
  source = "./code/${each.key}"
}

resource "google_app_engine_standard_app_version" "zabbix_to_pusub" {
  version_id = "v1"
  service    = "zabbix-to-pusub"
  runtime    = "python38"

  entrypoint {
    shell = "python ./index.py"
  }


  deployment {

    dynamic "files" {
      for_each = fileset("${path.module}/code", "*")
      content {
        name       = files.key
        source_url = "https://storage.googleapis.com/${google_storage_bucket.zabbix_to_pusub.name}/${files.key}"
      }
    }
  }

  env_variables = {
    port        = "8080"
    GCP_PROJECT = var.project
    GCP_TOPIC   = module.topic_zabbix_to_pubsub.topic.name
  }

  automatic_scaling {
    max_concurrent_requests = 10
    min_idle_instances      = 1
    max_idle_instances      = 3
    min_pending_latency     = "1s"
    max_pending_latency     = "5s"
    standard_scheduler_settings {
      target_cpu_utilization        = 0.5
      target_throughput_utilization = 0.75
      min_instances                 = 2
      max_instances                 = 10
    }
  }

  delete_service_on_destroy = true
  service_account           = google_service_account.zabbix_to_pusub.email
}
