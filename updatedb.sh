#!/bin/bash
#
# Load mqtt json into nosql db
#
yolink="$@"
NOSQL="/dev/shm/yolink.db"
State=$( jq -r '.data.state' <<< "${yolink}" )
AlertType=$( jq -r '.data.alertType' <<< "${yolink}" )
Event=$( jq -r '.event' <<< "${yolink}" )
Time=$( jq -r '.time' <<< "${yolink}" )
StateChangedAt=$( jq -r '.data.stateChangedAt' <<< "${yolink}" )
battery=$( jq -r '.data.battery' <<< "${yolink}" )
DeviceId=$( jq -r '.deviceId' <<< "${yolink}" )
Temperature=$( jq -r '.data.temperature' <<< "${yolink}" )
Humidity=$( jq -r '.data.humidity' <<< "${yolink}" )
#
# check if DB is defined
#
if [[ ! -f ${NOSQL} ]]
  then
    echo "No DB file - Creating"
    echo 'create table yolink(deviceId varchar(17), stateChangedAt int, time int,state varchar(10),alertType varchar(17),event varchar(17),temperature real,humidity real,battery varchar(1),deviceName varchar(30));' | sqlite3 ${NOSQL}
fi

if [[ $Event =~ "SmartRemoter" ]]
  then
    ./button.sh "${yolink}"&
fi
if [[ $Event =~ "DoorSensor" ]]
  then
    ./door.sh "${yolink}"&
fi
if [[ $Event =~ "THSensor" ]]
  then
    echo "Update RRD with tmep and humdity"
    ./tempupdate.sh "${yolink}"&
fi
if [[ $Event =~ "MotionSensor" ]]
  then
    echo "Movement detected"
    ./motion.sh "${yolink}"&
fi

if [[ $Event =~ "Report" ]]
  then
    result=`echo "update yolink set state=\"$State\", AlertType=\"$AlertType\",event=\"$Event\",temperature=\"$Temperature\",humidity=\"$Humidity\",battery=$battery, time=$Time where deviceId=\"$DeviceId\"; select changes(); " | sqlite3 ${NOSQL}` 
  else 
    result=`echo "update yolink set stateChangedAt = \"$StateChangedAt\", state=\"$State\", AlertType=\"$AlertType\",event=\"$Event\", battery=$battery,temperature=\"$Temperature\",humidity=\"$Humidity\", time=$Time where deviceId=\"$DeviceId\"; select changes(); " | sqlite3 ${NOSQL}` 
fi
if [[ $result -eq 0 ]]
  then
    echo "need to insert line"
    if [[ $Event =~ "Report" ]]
      then
	echo "insert into yolink(deviceId,state,AlertType,event,battery,temperature,humidity,time) values (\"$DeviceId\",\"$State\",\"$AlertType\",\"$Event\",$battery,${Temperature},$Humidity,$Time); select changes();"
        result=`echo "insert into yolink(deviceId,state,AlertType,event,battery,temperature,humidity,time) values (\"$DeviceId\",\"$State\",\"$AlertType\",\"$Event\",$battery,${Temperature},$Humidity,$Time); select changes();" |  sqlite3 ${NOSQL}`
      else
       result=`echo "insert into yolink(deviceId,stateChangedAt,state,AlertType,event,battery,temperature,humidity,time) values (\"$DeviceId\",\"$StateChangedAt\",\"$State\",\"$AlertType\",\"$Event\",$battery,$Temperature,$Humidity,$Time); select changes();" |  sqlite3 ${NOSQL}`
   fi
fi
echo $result
