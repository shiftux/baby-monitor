#!/bin/bash
# video format vars
WIDTH=650
HEIGHT=365
BITRATE=500000
FPS=20
AUDIO_CHANNELS=1

# script vars
SOUNDCARD="USB-Audio"
ALSA_HW="1"
PICAM_DIR=/opt/picam
proc=123

######### start #########
echo "############# $(date) #############"

######### checks #########
# check if soundcard is present and has device number 1
if [ $(cat /proc/asound/cards | grep $SOUNDCARD | awk '{print $1}') -eq "$ALSA_HW" ]; then
    echo "soundcard found"
else
    echo "ERROR: soundcard not detected"
    exit 1
fi

# check if stunnel is running
i=0
while [ $i -le 5 ]; do
    if /etc/init.d/stunnel4 status > /dev/null ; then
        echo "stunnel4 running"
        i=7
        break
    else
        echo "stunnel4 not running"
        sudo systemctl start stunnel4
    fi
    if [ $i -eq 5 ]; then
        echo "can not start stunnel4"
        exit 1
    fi
    sleep 1
    (( i++ ))
done


# check if nginx is running
i=0
while [ $i -le 5 ]; do
    if cat /usr/local/nginx/logs/nginx.pid > /dev/null ; then
        echo "nginx running"
        i=7
        break
    else
        echo "nginx not running"
        sudo systemctl start nginx
    fi
    if [ $i -eq 5 ]; then
        echo "can not start nginx"
        exit 1
    fi
    sleep 1
    (( i++ ))
done

######### preparation #########
cd $PICAM_DIR
sh $PICAM_DIR/make_dirs.sh
if [ $? -eq 0 ]; then
   echo "picam dirs created"
else
   echo "ERROR: could not create picam dirs"
   exit 1
fi

# give nginx time to start
sleep 5

######### start picam #########
i=0
START_COMMAND="$PICAM_DIR/picam --tcpout tcp://127.0.0.1:8181 --alsadev hw:$ALSA_HW,0 -w $WIDTH -h $HEIGHT -v $BITRATE -f $FPS -c $AUDIO_CHANNELS &"
while [ $i -le 5 ]; do
    eval $START_COMMAND
    proc=$!
    sleep 5
    ps -p $proc > /dev/null
    if [ $? -eq 0 ]; then
        echo "picam running"
        i=7
        break
    else
        echo "picam not running"
    fi
    if [ $i -eq 5 ]; then
        echo "can not start picam"
        exit 1
    fi
    sleep 5
    (( i++ ))
done

######### make sure stunnel is connected #########
i=0
CHECK_COMMAND="tail -n 12 /var/log/stunnel4/stunnel.log | grep \"Session id\""
while [ $i -le 3 ]; do
    eval $CHECK_COMMAND
    if [ $? -eq 0 ]; then
        echo "stunnel4 connected"
        i=7
        break
    else
        echo "stunnel4 not connected"
    fi
    if [ $i -eq 3 ]; then
        echo "can not connect stunnel4"
        kill -15 $proc
        exit 1
    fi
    sleep 5
    (( i++ ))
done

