resource "random_string" "random" {
  length           = 16
  special          = true
  override_special = "/@$"
  min_numeric      = 6
  min_special      = 2
  min_upper        = 3
}