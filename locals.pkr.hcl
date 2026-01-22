locals {
  image_name = "ubuntu-nginx-starbucks"
  build_time = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
}
