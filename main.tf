# -------------------------------------------------------------------------------------------------
# Establecemos la región donde vamos a desplegar nuestra infraestructura, e indicamos los recursos
# -------------------------------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1"
}

# ----------------------------------------
# Establecemos la VPC de nuestro proyecto
# ----------------------------------------
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "MyVPC-Terraform"
  }
}

# -------------------------------------------------------------------------------------------------
# Establecemos una subred pública en la AZ:us-east-1a, y la asociamos a la VPC de nuestro proyecto
# -------------------------------------------------------------------------------------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "MyPublicSubnet-Terraform"
  }
}

# ---------------------------------------------------------------- 
# Establecemos una puerta de enlace para tener acceso a Internet
# ----------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyVPC-IGW-Terraform"
  }
}


# ---------------------------------------------------------------------------
# Vinculamos la puerta de enlace con la tabla de enrutamiento de nuestra VPC
# ---------------------------------------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "MyPublicRouteTable-Terraform"
  }
}


# ------------------------------------------------------------------------
# Asociamos la subred pública con la tabla de enrutamiento de nuestra VPC
# ------------------------------------------------------------------------
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# --------------------------------------------------------------------------------------------------
# Creamos un grupo de seguridad que permita tráfico entrante por los puertos: 22 (SSH), y 80 (HTTP)
# --------------------------------------------------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "WebSG-Terraform"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSG"
  }
}

# ---------------------------------------------------
# Buscamos la última versión del S.O: Amazon Linux 2
# ---------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}



# --------------------------------------------------------------------------------------------------------------------
# Definimos una instancia EC2 con el S.O: Amazon Linux 2
# Una vez creada la instancia, mediante el script: user-data.sh, configuramos los servicios y la aplicación a ejecutar
# --------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data                   = file("user-data.sh")
  
  tags = {
    Name = "Web-Server-Terraform"
  }
}



# --------------------------------------------------------------------------
# Creamos una variable de salida con la IP pública de la instancia y la URL
# --------------------------------------------------------------------------
output "IP_pública" {
  value = aws_instance.web_server.public_ip
}

output "URL_Acceso_Aplicación" {
  value = "http://${aws_instance.web_server.public_ip}/index.php"
}


