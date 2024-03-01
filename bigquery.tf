resource "google_bigquery_dataset" "zabbix" {
  dataset_id                  = "zabbix"
  friendly_name               = "Zabbix"
  description                 = "This is a history of Zabbix Stream"
  location                    = "EU"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }
}

resource "google_bigquery_table" "history" {
  deletion_protection = false

  dataset_id = google_bigquery_dataset.zabbix.dataset_id
  table_id   = "history"

  time_partitioning {
    type = "DAY"
  }

  labels = {
    env = "default"
  }

  schema = <<EOF
[
  {
    "name": "ns",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "ns of the event"
  },
  {
    "name": "ts",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "timestamp of the event"
  },
  {
    "name": "clock",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "timestamp of the event"
  },
  {
    "name": "severity",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "severity of the event"
  },
  {
    "name": "eventid",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "ID of the event"
  },
  {
    "name": "value",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "allways 1"
  },
  {
    "name": "name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "name"
  },
  {
    "name": "hosts",
    "type": "RECORD",
    "mode": "REPEATED",
    "fields": [
        {
            "name": "host",
            "type": "STRING",
            "mode": "NULLABLE"
        },
        {
            "name": "name",
            "type": "STRING",
            "mode": "NULLABLE"
        }],
    "description": "host in alert"
  },
  {
    "name": "groups",
    "type": "STRING",
    "mode": "REPEATED",
    "description": "groups in alert"
  },
  {
    "name": "tags",
    "type": "RECORD",
    "mode": "REPEATED",
    "fields": [
        {
            "name": "tag",
            "type": "STRING",
            "mode": "NULLABLE"
        },
        {
            "name": "value",
            "type": "STRING",
            "mode": "NULLABLE"
        }],
    "description": "tag in alert"
  }
]
EOF
}

resource "google_project_iam_member" "viewer" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "editor" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription" "zabbix_to_pusub" {
  name  = "bq-history-subscription"
  topic = module.topic_zabbix_to_pubsub.topic.id

  bigquery_config {
    table            = "${google_bigquery_table.history.project}.${google_bigquery_table.history.dataset_id}.${google_bigquery_table.history.table_id}"
    use_topic_schema = true
  }

  depends_on = [google_project_iam_member.viewer, google_project_iam_member.editor]

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.example_dead_letter.id
    max_delivery_attempts = 10
  }
}

resource "google_pubsub_topic" "example_dead_letter" {
  name = "example-topic-dead-letter"
}
