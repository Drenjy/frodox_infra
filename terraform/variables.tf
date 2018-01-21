variable project {
  description = "Project ID"
}

variable zone {
  description = "Instance zone"
  default     = "europe-west1-b"
}

variable region {
  description = "Region"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable disk_image {
  description = "Disk image to use for VM creation"
}
