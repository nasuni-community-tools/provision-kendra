########################################################
##  Developed By  :   Pradeepta Kumar Sahu
##  Project       :   Nasuni Kendra Integration
##  Organization  :   Nasuni Labs   
#########################################################

variable "aws_profile" {
  type    = string
  default = "nasuni"
}

variable "user_secret" {
  type    = string
  default = "prod/nac/jc"
}

variable "region" {
  description = "Region for Kendra cluster"
  type        = string
  default     = "us-east-2"
}

variable "admin_secret" {
  default = "nct/nce/os/admin"
}

