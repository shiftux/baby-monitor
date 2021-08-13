#!/bin/bash
# video format vars
WIDTH=650
HEIGHT=365
BITRATE=500000
FPS=20
AUDIO_CHANNELS=1
AUIDO_AMPLIFICATION=2

# script vars
SOUNDCARD="USB-Audio"
PICAM_DIR=/opt/picam
proc=123

######### helper functions #########
check_function () { # $1:CHECK_NAME, $2:ITERATIONS, $3:SLEEP_TIME
    i=0
    while [ $i -le "$2" ]; do
        if eval "$CHECK_COMMAND"; then
            echo "$1 OK"
            i=100
            break
        else
            echo "$1 not OK"
            eval "$START_COMMAND"
        fi
        if [ $i -eq "$2" ]; then
            echo "can not run $1"
            eval "$COMMAND_IF_CHECK_FAILED"
            exit 1
        fi
        sleep "$3"
        (( i++ ))
    done
}

######### start #########
echo "############# $(date) #############"

######### checks #########
# check if soundcard is present and find its device number
if [ "$(grep $SOUNDCARD /proc/asound/cards)" ]; then
    echo "soundcard found"
    ALSA_HW="$(grep $SOUNDCARD /proc/asound/cards | awk '{print $1}')"
else
    echo "ERROR: soundcard not detected"
    exit 1
fi

# # check if in AP mode
# CHECK_COMMAND="test -f /etc/raspiwifi/host_mode"
# START_COMMAND="true"
# COMMAND_IF_CHECK_FAILED="true"
# check_function "HostMode" 5 1

# check if stunnel is running
CHECK_COMMAND="/etc/init.d/stunnel4 status > /dev/null"
START_COMMAND="sudo systemctl start stunnel4"
COMMAND_IF_CHECK_FAILED="true"
check_function "stunnel4" 5 1

# check if nginx is running
CHECK_COMMAND="cat /usr/local/nginx/logs/nginx.pid > /dev/null"
START_COMMAND="sudo systemctl start nginx"
COMMAND_IF_CHECK_FAILED="true"
check_function "nginx" 5 1

# check if internet is reachable
CHECK_COMMAND="curl -I -s 'http://clients3.google.com/generate_204' | grep 204 > /dev/null"
START_COMMAND="true"
COMMAND_IF_CHECK_FAILED="true"
check_function "internet" 5 5

######### preparation #########
cd $PICAM_DIR || exit 1
if sh $PICAM_DIR/make_dirs.sh; then
   echo "picam dirs created"
else
   echo "ERROR: could not create picam dirs"
   exit 1
fi

# give nginx time to start
sleep 5

######### start picam #########
i=0
START_COMMAND="$PICAM_DIR/picam --tcpout tcp://127.0.0.1:8181 --alsadev hw:$ALSA_HW,0 -w $WIDTH -h $HEIGHT -v $BITRATE \
    -f $FPS -c $AUDIO_CHANNELS --volume $AUIDO_AMPLIFICATION --time --timeformat \"%H:%M:%S  \" -- timelayout bottom,left &"
while [ $i -le 5 ]; do
    eval "$START_COMMAND"
    proc=$!
    sleep 5
    if ps -p $proc > /dev/null; then
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
CHECK_COMMAND="tail -n 12 /var/log/stunnel4/stunnel.log | grep \"Session id\" || tail -n 12 /var/log/stunnel4/stunnel.log.1 | grep \"Session id\""
START_COMMAND="true"
COMMAND_IF_CHECK_FAILED="kill -15 $proc"
check_function "stunnel4_connection" 3 5
