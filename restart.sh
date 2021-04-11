#!/bin/bash

minestatus=$(ps aux | grep minecraft_server.jar | grep java) ;
screenstatus=$(screen -ls | grep "Minecraft server") ;
date=$(date) ;

if [ -z "$minestatus" ] ;
  then
    echo $date
    echo "Minecraft server is DOWN, starting" ;
    if [ -n "$screenstatus" ]
      then
        echo "screen is on, killing" ;
        screen -X -S "Minecraft server" kill ;
    fi
    cd /opt/Minecraft && screen -dmS "Minecraft server" java -Xmx2048M -Xms2048M -jar minecraft_server.jar nogui ;
  else
    sleep 2
#   echo "Minecraft server is UP, nothing to do" ;
fi

exit 0
