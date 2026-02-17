# shud be used as var.ec2-instance-type , var.ami to assign the defualt values

variable ec2-instance-type {
   default = "t3.micro"
   type = string
}

variable ami {
   default = "ami-019715e0d74f695be"
   type = string
}
