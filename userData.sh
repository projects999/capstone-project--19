#!/bin/bash
dnf update -y
dnf install cronie -y
systemctl enable crond
systemctl start crond
mkdir -p /home/ec2-user/logs
echo "Project 19 Started" > /home/ec2-user/logs/app.log
echo "*/5 * * * * aws s3 cp /home/ec2-user/logs/app.log s3://project-19-backup-bucket/app-\$(date + \%Y-\%m-\%d-\%H-\%M).log" > /var/spool/cron/ec2-user
chown ec2-user:ec2-user /var/spool/cron/ec2-user
chmod 600 /var/spool/cron/ec2-user
systemctl restart crond