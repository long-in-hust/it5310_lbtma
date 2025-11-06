#!/bin/bash

docker run -t -d -p 8181:8181 -p 8101:8101 -p 5005:5005 -p 830:830 -p 6653:6653 --name onos8 onosproject/onos

curl --fail -sSL --user onos:rocks --noproxy p4.it530.hust.local \
    -X POST -HContent-Type:application/octet-stream \
	'http://p4.it530.hust.local:8181/onos/v1/applications?activate=true' \
	--data-binary @p4-stm-0.0.1.oar
