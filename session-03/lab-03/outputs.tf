output "instance_ids" {
  value = [ for k, v in aws_instance.instance : v.id ]
}