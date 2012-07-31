#!/bin/bash -x

sudo /sbin/rmmod etest
sudo /sbin/rmmod main

sudo /sbin/insmod etest.ko &&
sudo /sbin/insmod main.ko

