#!/bin/bash
# Restart the network and docker services

sudo ethtool -K eno1 highdma off

service docker stop
sudo /etc/init.d/networking restart
service docker start