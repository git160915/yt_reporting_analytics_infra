variable "buckets" {
  description = "Map of bucket configurations. The key is the bucket name, and the value is an object with versioning and ACL settings."
  type = map(object({
    versioning_enabled = bool
  }))
}
