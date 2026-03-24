#!/bin/bash

yum update -y
yum -y remove httpd
yum -y remove httpd-tools
yum install -y httpd php

systemctl start httpd
systemctl enable httpd

usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
cd /var/www/html

curl https://raw.githubusercontent.com/hashicorp/learn-terramino/master/index.php -O
