#!/bin/bash
sudo apt install -y nginx
sudo systemctl start nginx && sudo systemctl enable nginx
