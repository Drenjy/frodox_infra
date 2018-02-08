variable source_ranges {
  description = "Allowed IP addresses"
  default     = ["0.0.0.0/0"]
}

variable allow_firewall_protocol {
  description = "Allowed protocol for connection"
  default     = "tcp"
}

variable allow_firewall_ports {
  description = "Allowed ports in firewall"
  default     = ["22"]
}

variable firewall_rule_name {
  default = "default-allow-ssh"
}
