variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable zone {
  description = "Instance zone"
  default     = "europe-west1-b"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}
