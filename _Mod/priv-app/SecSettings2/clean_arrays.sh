#!/bin/bash

cd res
find values-* -name arrays.xml | while read file; do
  if grep -q window_animation_scale_entries $file; then
    LINE=$(grep -n window_animation_scale_entries $file | egrep -o '^[^:]+')
    sed -i "${LINE},$(expr ${LINE} + 26)d" $file
  fi
done
cd ..