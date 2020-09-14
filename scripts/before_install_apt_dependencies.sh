#!/bin/sh
sudo apt remove -y ansible
sudo apt -y autoremove
sudo apt update

# Python3 & Pip3
sudo apt install -y software-properties-common

# Linting
sudo apt install -y yamllint
sudo apt install -y shellcheck
