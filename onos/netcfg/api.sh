curl -X POST -H "content-type:application/json" \
    http://p4.it530.hust.local:8181/onos/v1/network/configuration \
    -d @netcfg.json --user onos:rocks
