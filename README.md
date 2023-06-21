# yolink_mon
is a simple consumer of the MQTT feed from yolink that populates a sqlite DB.
It simply connects to the yolink feed and then consumes the json data and parses to populate the DB. It's trivial to trigger events from the feed and call from inside updatedb.sh you'll notice external shell scripts based on different types of devices.

copy yolink.conf.example to .yolink.conf and fill in your credentials from the yolink app

You could of course just use home assistant or any other HA endpoint that can accept a yolink but my use case was merely to check on door status and switch off an ecobee-controlled AC unit.
