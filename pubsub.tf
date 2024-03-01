module "topic_zabbix_to_pubsub" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/pubsub?ref=v29.0.0"
  project_id = var.project
  name       = "topic_zabbix_to_pubsub"
  iam = {
    "roles/pubsub.viewer"     = ["user:mgoulin@mgen.fr"]
    "roles/pubsub.publisher"  = ["serviceAccount:${google_service_account.zabbix_to_pusub.email}"]
    "roles/pubsub.subscriber" = ["user:mgoulin@mgen.fr"]
  }
  schema = {
    msg_encoding = "JSON"
    schema_type  = "AVRO"
    definition = jsonencode({

      "type" = "record",
      "name" = "Avro",
      "fields" = [{
        "name" = "ts",
        "type" = "string"
        }, {
        "name" = "clock",
        "type" = "int"
        },
        {
          "name" = "ns",
          "type" = "int"
        },
        {
          "name" = "value",
          "type" = "int"
        },
        {
          "name" = "eventid",
          "type" = "int"
        },
        {
          "name" = "name",
          "type" = "string"
        },
        {
          "name" = "severity",
          "type" = "int"
        },
        {
          "name" = "hosts",
          "type" : {
            "type" : "array",
            "items" : {
              "name" : "host",
              "type" : "record",
              "fields" : [{
                "name" = "host",
                "type" = "string"
                },
                {
                  "name" = "name",
                  "type" = "string"
              }]
            }
          }
        },
        {
          "name" = "groups",
          "type" : {
            "type" : "array",
            "items" : {
              "name" : "group",
              "type" : "string",
            }
          }
        },
        {
          "name" = "tags",
          "type" : {
            "type" : "array",
            "items" : {
              "name" : "tag",
              "type" : "record",
              "fields" : [{
                "name" = "tag",
                "type" = "string"
                },
                {
                  "name" = "value",
                  "type" = "string"
              }]

            }
          }
        }
      ]
    })
  }
}
