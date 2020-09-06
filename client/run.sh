#!/bin/bash
docker run -it \
   --net=host \
   --device=/dev/dri/card0:/dev/dri/card0 \
   --device=/dev/dri/renderD128:/dev/dri/renderD128 \
   --device=/dev/snd/timer:/dev/snd/timer \
   --device=/dev/snd/pcmC0D0p:/dev/snd/pcmC0D0p \
   --device=/dev/snd/controlC0:/dev/snd/controlC0 \
   --device=/dev/snd/seq:/dev/snd/seq \
   --env="DISPLAY" --env="QT_X11_NO_MITSHM=1" --env="QT_GRAPHICSSYSTEM='native'" \
   --ipc host \
   --volume="$HOME/.Xauthority:/root/.Xauthority:rw" bluecherry-client
