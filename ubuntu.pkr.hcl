packer {
  required_version = ">= 1.9.0"

  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.1"
    }
  }
}

source "azure-arm" "ubuntu_image" {

  # 🔐 Authentication
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # 📦 Base Image
  image_publisher = "canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"

  # 🖥 Temp VM
  location = var.location
  vm_size  = var.vm_size
  os_type  = "Linux"

  # 🖼 Managed Image Output
  managed_image_name                = "${local.image_name}-${var.image_version}"
  managed_image_resource_group_name = "Custom-image-rg"

  # 🏷 Tags
  azure_tags = {
    environment = "dev"
    owner       = "devops-team"
    project     = "starbucks"
    created_by  = "packer"
    build_time  = local.build_time
  }
}

build {
  name    = "ubuntu-nginx-image"
  sources = ["source.azure-arm.ubuntu_image"]

  provisioner "shell" {
    execute_command = "sudo -E sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "set -e",
      "export DEBIAN_FRONTEND=noninteractive",

      # 🔄 Update system
      "apt-get update -y",
      "apt-get install -y --no-install-recommends software-properties-common ca-certificates curl git nginx",

      # 🌐 Enable nginx at boot
      "systemctl enable nginx",
      "systemctl restart nginx",

      # 📥 Clone app (fast)
      "rm -rf /tmp/starbucks-clone",
      "git clone --depth=1 https://github.com/devopsinsiders/starbucks-clone.git /tmp/starbucks-clone",
      "rm -rf /var/www/html/*",
      "cp -r /tmp/starbucks-clone/* /var/www/html/",
      "chown -R www-data:www-data /var/www/html",

      # 🧹 Cleanup (image size reduce)
      "apt-get autoremove -y",
      "apt-get clean",
      "rm -rf /var/lib/apt/lists/*",
      "rm -rf /tmp/*",

      # 🔒 Azure required deprovision (LAST step)
      "/usr/sbin/waagent -force -deprovision+user",
      "sync"
    ]
  }
}
