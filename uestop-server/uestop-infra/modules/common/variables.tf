variable "security-group" {
  type = object({
    port = number
    name = string
  })
}