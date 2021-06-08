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
  sudo mount -o loop  $image_file $mount_dir
fi

if [ ! "$(ls -A $mount_dir/proc)" ]; then
  sudo mount -o bind,ro /dev $mount_dir/dev
  sudo mount -o bind,ro /dev/pts $mount_dir/dev/pts
  sudo mount -t proc none $mount_dir/proc
else
  echo "/proc, /dev already mounted to $mount_dir"
fi

sudo LANG=C.UTF-8 chroot $mount_dir /bin/bash
