#!/bin/bash
# Restart the network and docker services

service docker stop
sudo /etc/init.d/networking restart
service docker start