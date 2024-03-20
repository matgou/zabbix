output "zabbix_server_ip" {
  value = "https://${module.zabbix_server.external_ip}"
}
output "vault_server_ip" {
  value = "https://${module.vault_server.external_ip}:8200"
}
output "zabbix-to-pubsub" {
  value = "https://zabbix-to-pusub-dot-sandbox-mgoulin.ew.r.appspot.com/"
}

