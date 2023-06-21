#/bin/bash
#
# yolink mqtt feed to namedpipe
#
CFG_FILE=~/.yolink.conf
if [[ -f ${CFG_FILE} ]]
  then
    CFG_CONTENT=$(cat $CFG_FILE |egrep 'UA|SEC' | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
    eval "$CFG_CONTENT"
  else
    echo "Error no config file"
    exit 2
fi
if [ -z ${UA+x} ] || [ -z ${SEC+x} ]
  then
    echo "Define credentials"
    exit 3
fi

ROOT_DIR="/dev/shm"
YOTOKEN="${ROOT_DIR}/yotoken"
YOPIPE="~/yolink_mon/yolink.log"
if [ ! -p  "$YOPIPE" ]
  then
    mkfifo $YOPIPE
fi
login()
{
curl -s -X POST -d "grant_type=client_credentials&client_id="${UA}"&client_secret=${SEC}" https://api.yosmart.com/open/yolink/token > "$YOTOKEN"
cat "$YOTOKEN"
}
geninfo()
{
cat <<EOF
{  "method":"Home.getGeneralInfo" }
EOF
}

gethub()
{
curl -s --location --request POST 'https://api.yosmart.com/open/yolink/v2/api' --header 'Content-Type: application/json' --header "Authorization: Bearer ${TOKEN}" -d "$(geninfo)" > "${ROOT_DIR}/getHubList"
return=`jq -r '.code' "${ROOT_DIR}/getHubList"`
}

getdevicelist()
{
cat <<EOF
{  "method":"Home.getDeviceList" }
EOF
}

getDeviceList()
{
curl -s --location --request POST 'https://api.yosmart.com/open/yolink/v2/api' --header 'Content-Type: application/json' --header "Authorization: Bearer ${TOKEN}" -d "$(getdevicelist)" > "${ROOT_DIR}/getDeviceList"
}



gettoken()
{
if test -f "$YOTOKEN"
  then
    TOKEN=`jq .access_token "$YOTOKEN" | sed 's/\"//g'`
    gethub
    if [[ $return != "000000" ]]
      then
        login
    fi
  else
    login
fi
TOKEN=`jq .access_token "$YOTOKEN" | sed 's/\"//g'`
gethub
}



#### start here check we have a token
if [ -z "$TOKEN" ];
  then
    # get token and login
    gettoken
fi

HubID=`jq -r '.data[]' "${ROOT_DIR}/getHubList"`
#echo 
#echo $HubID
#echo
#echo $TOKEN
#echo

getDeviceList
cat "${ROOT_DIR}/getDeviceList" | jq -r '.data[] | .[] | "\(.type) \(.deviceId) \(.token) \"\(.name)\""'

mosquitto_sub -u ${TOKEN} -p 8003 -h api.yosmart.com -t yl-home/${HubID}/+/report > $YOPIPE
echo "Exit code - $?"

