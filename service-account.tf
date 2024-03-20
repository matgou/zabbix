resource "google_service_account" "vault" {
  account_id = "vault-sandbox"

}

resource "google_service_account_key" "vault" {
  service_account_id = google_service_account.vault.name
}

output "key" {
  value     = base64decode(google_service_account_key.vault.private_key)
  sensitive = true
}

resource "google_service_account" "zabbix-token" {
  account_id = "zabbix-token"
}
resource "google_service_account_iam_member" "zabbix-token-vault" {
  service_account_id = google_service_account.zabbix-token.id
  role               = "roles/iam.serviceAccountKeyAdmin"
  member             = "serviceAccount:${google_service_account.vault.email}"
}

output "zabbix-sa-email" {
  value = google_service_account.zabbix-token.email
}
