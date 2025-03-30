variable "comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = null
}

variable "delegation_set_id" {
  description = "The ID of the reusable delegation set whose NS records you want to assign to the hosted zone"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Whether to destroy all records (possibly managed outside of Terraform) in the zone when destroying the zone"
  type        = bool
  default     = false
}

variable "name" {
  description = "Hosted Zone Name"
  type        = string
  default     = ""
}

variable "vpc" {
  description = "VPC(s) to associate with private hosted zone"
  type = list(object({
    id     = string
    region = string
  }))
  default = []
}
