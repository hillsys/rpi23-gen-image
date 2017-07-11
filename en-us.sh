#!/bin/bash

APT_SERVER="mirrors.kernel.org" \
APT_PROXY="localhost:3142" \
APT_INCLUDES="iamerican,ibritish,ienglish-common,task-english,wamerican" \
HOSTNAME="pi2-stretch" \
USER_NAME="administrator" \
USER_LOCALE="en_US.UTF-8" \
ENABLE_CONSOLE=false \
ENABLE_DHCP=true \
ENABLE_IPV6=false \
ENABLE_SOUND=false \
UBOOTSRC_DIR="/mnt/PI2-Build/u-boot" \
NET_ADDRESS="" \
NET_MASK="" \
NET_GATEWAY="" \
NET_DNS_1="" \
NET_DNS_2="" \
NET_NTP_1="0.us.pool.ntp.org" \
NET_NTP_2="1.us.pool.ntp.org" \
./rpi23-gen-image.sh