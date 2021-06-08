#!/bin/bash

#
# Copyright (c) 2021, Johns Hopkins University - Order Lab.
#
#    All rights reserved.
#    Licensed under the Apache License, Version 2.0 (the "License");
#

if [ $# -ne 2 ]; then
  echo "Usage: $0 IMAGE_FILE MOUNT_DIR"
  exit 1
fi

image_file=$1
mount_dir=$2

if [[ $image_file != *.img ]]; then
  echo "Image file $image_file does not end with .img"
  exit 1
fi

if [ ! "$(ls -A $mount_dir)" ]; then
  echo "Mount directory $mount_dir is empty"
  exit 0
fi

sudo umount $mount_dir/dev/pts
sudo umount $mount_dir/dev
sudo umount $mount_dir/proc
sudo umount $mount_dir
