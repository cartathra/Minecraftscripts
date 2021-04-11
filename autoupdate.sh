#!/bin/bash

cd /tmp
wget -q https://launchermeta.mojang.com/mc/game/version_manifest.json

##---------- Variabler som kan ändras ---------------
latest=$(cat /tmp/version_manifest.json | grep -o -E "release\"\:.{0,10}" | cut -d "\"" -f 3) ;
running=$(cat /opt/Minecraft/runningversion) ;
minestatus=$(ps aux | grep minecraft_server.jar | grep java | grep java | head -1 | cut -d " " -f 1) ;
screenstatus=$(screen -ls | grep "Minecraft server") ;
date=$(date) ;

##---------------------------------------
echo "--==$date==--"
echo "Looking for new server version" ;
##--------------------------------------
##--------- Download Function ---------------
download () {
echo "New version available, downloading" ;
cd /opt/Minecraft
#wget https://s3.amazonaws.com/Minecraft.Download/versions/$latest/minecraft_server.$latest.jar
wget https://launcher.mojang.com/v1/objects/bb2b6b1aefcd70dfd1892149ac3a215f6c636b07/server.jar
if [ $minestatus == "root" ]
  then
    echo "Minecraft server still running, saving and shutting down" ;
    screen -S "Minecraft server" -X stuff '/save-all'`echo -ne '\015'` ;
    screen -S "Minecraft server" -X stuff '/say "server going down for update to version $latest in 10 min, find a safe place to hide"'`echo -ne '\015'` ;
    sleep 600 ;
    screen -S "Minecraft server" -X stuff '/stop'`echo -ne '\015'` ;
    sleep 15;
fi
rm -f minecraft_server.jar
ln -s minecraft_server.$latest.jar minecraft_server.jar
echo "Starting up Minecraft again" ;
/opt/Minecraft/bin/minecraftrestart.sh
echo "$latest" > /opt/Minecraft/runningversion
}

##-------- Main script ----------------
if [ $latest != $running ];
  then
    download
  else
    echo "No new version available, nothing to do" ;
fi

rm -f /tmp/version_manifest.json
exit 0
