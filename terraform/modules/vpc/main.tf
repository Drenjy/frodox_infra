resource "google_compute_firewall" "firewall_ssh" {
  name    = "${var.firewall_rule_name}"
  network = "default"

  allow {
    protocol = "${var.allow_firewall_protocol}"
    ports    = "${var.allow_firewall_ports}"
  }

  source_ranges = "${var.source_ranges}"
}
