variable "name_prefix" {
    type =  string
    default =  "Django-app"
}

variable "key_name" {
    type =  string
    default =  "app-key"
}

variable "vpc_security_group_ids" {
    type = list(string)
    description = "security group id"
  
}

variable "instance_type" {
    type =  string
    default =  "t2.micro"
}
  
variable "desired_capacity" {

    type =  number
    default =  2
}

variable "max_size" {

    type =  number
    default =  3
  
}

variable "min_size" {

    type =  number
    default =  1
  
}