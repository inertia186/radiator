#!/bin/bash

gource ./ --user-image-dir images --hide usernames -s 0.5 -b 000000 \
  --start-date '2017-05-27 17:23' \
  -1280x720 --output-ppm-stream - |\
  ffmpeg -y -r 28 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset slow \
  -crf 28 -threads 0 output.mp4

