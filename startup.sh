#!/bin/bash
#
cd ~/yolink_mon
while true
do
    cat ~/yolink_mon/yolink.log |while read line; do ./updatedb.sh "$line"; echo $line | jq; done&
    ./mq-l.sh
    echo "Restart"
    logger -t yolink mqtt restarted
done
