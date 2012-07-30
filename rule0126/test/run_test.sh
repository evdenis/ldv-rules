#!/bin/bash -x

sudo rmmod etest
sudo rmmod main

sudo insmod etest.ko &&
sudo insmod main.ko

