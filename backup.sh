#!/bin/bash

## This is a backupscript for minecraft, syncing the world directory to a mounted network drive.
## Written by Patrik Gustafsson (cartathra)

## NEVER CHANGE THESE VARIABLES
mounted=$(cat /proc/mounts |grep 192.168.12.10 | cut -d ":" -f1)
olddirs=$(find /mnt/nas/ -maxdepth 1 -mindepth 1 -type d -ctime +7);
dateshort=$(date +%y%m%d) ;
date=$(date) ;
screenstatus=$(screen -ls | grep "Minecraft server") ;
minestatus=$(ps aux | grep minecraft_server.jar | grep java) ;

## Options that can be changed
mountdir=/mnt/nas/
backupdirname=Minecraft-$dateshort
backupdir="$mountdir$backupdirname" ;
debug="" ;
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

col=80 # change this to whatever column you want the output to start at

### FUNCTIONS

## Backup minecraft world to backupdir
backup () {
if [ -d "$backupdir" ] ;
  then
    rsync -rp /opt/Minecraft/world $backupdir ;
  else
    mkdir $backupdir > /dev/null 2>&1 ;
    if [ $? -eq 0 ];
      then
        rsync -rp /opt/Minecraft/world $backupdir ;
      else
        echo -ne "\n" && echo -n "failed on creating backup directory" ;
        printf '%s%*s%s' "$RED" 67 "[FAIL]" "$NORMAL" && echo -ne "\n" && exit 1 ;
    fi
fi
}

backup_verbose () {
if [ -d "$backupdir" ] ;
  then
    rsync -vrp /opt/Minecraft/world $backupdir ;
  else
    mkdir $backupdir > /dev/null 2>&1 ;
    if [ $? -eq 0 ];
      then
        rsync -vrp /opt/Minecraft/world $backupdir ;
      else
        echo -ne "\n" && echo -n "failed on creating backup directory" ;
        printf '%s%*s%s' "$RED" 67 "[FAIL]" "$NORMAL" && echo -ne "\n" && exit 1 ;
    fi
fi
}

## Turn off autosaving before backing up if minecraft server is running
turnoff () {
echo -n "Saving running world" ;
screen -S "Minecraft server" -X stuff '/save-all'`echo -ne '\015'` ;
sleep 5s ;
printf '%s%*s%s' "$GREEN" $col "[OK]" "$NORMAL" && echo -ne "\n" ;
echo -n "Turning off automatic save while backing up" ;
screen -S "Minecraft server" -X stuff '/save-off'`echo -ne '\015'` ;
sleep 5s ;
printf '%s%*s%s' "$GREEN" 57 "[OK]" "$NORMAL" && echo -ne "\n" ;
echo -n "Backing up Minecraft world" ;
if [ -z "$debug" ] ;
  then
    backup
    printf '%s%*s%s' "$GREEN" 74 "[OK]" "$NORMAL" && echo -ne "\n" ;
  else
    backup_verbose
fi
sleep 10s ;
echo -n "Turning on automatic save again" ;
screen -S "Minecraft server" -X stuff '/save-on'`echo -ne '\015'` ;
sleep 5s ;
printf '%s%*s%s' "$GREEN" 69 "[OK]" "$NORMAL" && echo -ne "\n" ;
}

## remove more than 7 days old backup dirs
cleanup () {
if [[ -n $olddirs ]] ;
  then
    for dir in $olddirs
      do
      if [ -d "$dir" ] ;
        then
          echo -n "removing old backups $dir"
          rm -rf $dir ;
          sleep 2
          printf '%s%*s%s' "$GREEN" $col "[OK]" "$NORMAL" && echo -ne "\n" ;
      fi
      done
fi
}

## Check if backupdir is mounted and try to fix it if not.
mountcheck () {
if [ "$mounted" == "192.168.12.10" ] ;
  then
    echo "Backup directory reachable, continuing with backup" ;
  else
    echo -n "Backup directory is not reachable attempting to mount" ;
    mount /mnt/nas/ > /dev/null 2>&1  ;
    sleep 5s ;
    if [ $? -eq 0 ] ;
      then
        unset mounted
        mounted=$(cat /proc/mounts |grep 192.168.12.10 | cut -d ":" -f1);
        if [ "$mounted" == "192.168.12.10" ] ;
          then
            printf '%s%*s%s' "$GREEN" 47 "[OK]" "$NORMAL" && echo -ne "\n" ;
          else
            printf '%s%*s%s' "$RED" 49 "[FAIL]" "$NORMAL" && echo -ne "\n" && exit 1 ;
        fi
    fi
fi
}

## Main Script
echo "---===$date===---" ;
mountcheck
cleanup

if [ -z "$minestatus" ] ;
  then
    echo "Minecraft server is DOWN, safe to backup" ;
    echo -n "Backing up Minecraft world" ;
    if [ -z "$debug" ] ;
      then
        backup
        printf '%s%*s%s' "$GREEN" 74 "[OK]" "$NORMAL" && echo -ne "\n" ;
      else
        backup_verbose
    fi
  else
    turnoff
fi

echo "Backup completed successfully!"

exit 0
