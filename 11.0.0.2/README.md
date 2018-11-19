# ACE on ICP Integration Micro services Standard Operating Environment Image

IBM App Connect Enteprise on IBM Cloud Private to Microservices Principles - Integration MicroServices Standard Operating Environment Image



# Overview

This repository holds ACE Integration Micro Services Standard (or base) operating environment image

ACE v11.0.0.2 + MQ client v9.1 + Standard operating environment i.e. fixed deployment for ACE v11.
mqsibar is used at image build time to preload a liveliness probe packaged in SoE.bar

The liveliness probe can be tested as follows

http://<ipaddress>:<exposed port>/livelinessProbe/v1/message
Example request data: {“Messages”:[“test”]}
Example response {"Messages":{"item":"ace-server:20181119-013513"}}

This image was create by IBM Australia subject matter experts Peter Jessup, Do Nguyen and Dave Arnold
 as part of a modern, agile integration to microservices principles demonstration. However, it can be
used independently of that demonstration.
