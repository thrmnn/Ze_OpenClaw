#!/bin/bash
# Get Windows host IP from WSL
cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
