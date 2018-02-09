MongoDB replica set example with SSL
====================================

This is an example how to run MongoDB replica set.

See `Makefile` for the exact commands and for the process of generating SSL certificates.

Example shell transcript:

```shell
$ # cleanup
$ rm -rf a b
$ 
$ make run-mongod-a  &
[1] 19284
...
$ 
$ make run-mongod-b  & 
[2] 19312
...
$ 
$ make rs-initiate 
mongo --port 27017 --eval \
        'rs.initiate({_id: "testrs", version: 1, members: [{_id: 0, host: "localhost:27017"}]})'
MongoDB shell version v3.4.5
connecting to: mongodb://127.0.0.1:27017/
2017-06-18T13:00:08.624+0200 I NETWORK  [thread1] connection accepted from 127.0.0.1:45948 #1 (1 connection now open)
...
2017-06-18T13:00:10.660+0200 I REPL     [rsSync] transition to primary complete; database writes are now permitted
$ 
$ make rs-status    # will not work - need to authenticate
mongo --port 27017 -u root -p rootpwd --eval 'rs.status()' admin
MongoDB shell version v3.4.5
connecting to: mongodb://127.0.0.1:27017/admin
2017-06-18T13:00:24.621+0200 E QUERY    [thread1] Error: Authentication failed. :
exception: login failed
$ 
$ make create-root-user 
mongo --port 27017 --eval \
        'db.createUser({user: "root", pwd: "rootpwd", roles: ["root"]})' admin
Successfully added user: { "user" : "root", "roles" : [ "root" ] }
$ 
$ make rs-status     # now it will work
mongo --port 27017 -u root -p rootpwd --eval 'rs.status()' admin
...
        "members" : [
                {
                        "_id" : 0,
                        "name" : "localhost:27017",
                        "health" : 1,
                        "state" : 1,
                        "stateStr" : "PRIMARY",
                        "uptime" : 54,
                        "optime" : {
                                "ts" : Timestamp(1497783646, 3),
                                "t" : NumberLong(1)
                        },
                        "optimeDate" : ISODate("2017-06-18T11:00:46Z"),
                        "infoMessage" : "could not find member to sync from",
                        "electionTime" : Timestamp(1497783608, 2),
                        "electionDate" : ISODate("2017-06-18T11:00:08Z"),
                        "configVersion" : 1,
                        "self" : true
                }
        ],
        "ok" : 1
... 
$ 
$ make rs-add-members 
mongo --port 27017 -u root -p rootpwd --eval 'rs.add("localhost:27117")' admin
...
2017-06-18T13:01:02.521+0200 I REPL     [ReplicationExecutor] Member localhost:27117 is now in state SECONDARY
$ 
$ make rs-status      
mongo --port 27017 -u root -p rootpwd --eval 'rs.status()' admin
...
        "members" : [
                {
                        "_id" : 0,
                        "name" : "localhost:27017",
                        "health" : 1,
                        "state" : 1,
                        "stateStr" : "PRIMARY",
                        "uptime" : 66,
                        "optime" : {
                                "ts" : Timestamp(1497783660, 1),
                                "t" : NumberLong(1)
                        },
                        "optimeDate" : ISODate("2017-06-18T11:01:00Z"),
                        "infoMessage" : "could not find member to sync from",
                        "electionTime" : Timestamp(1497783608, 2),
                        "electionDate" : ISODate("2017-06-18T11:00:08Z"),
                        "configVersion" : 2,
                        "self" : true
                },
                {
                        "_id" : 1,
                        "name" : "localhost:27117",
                        "health" : 1,
                        "state" : 2,
                        "stateStr" : "SECONDARY",
                        "uptime" : 5,
                        "optime" : {
                                "ts" : Timestamp(1497783660, 1),
                                "t" : NumberLong(1)
                        },
                        "optimeDurable" : {
                                "ts" : Timestamp(1497783660, 1),
                                "t" : NumberLong(1)
                        },
                        "optimeDate" : ISODate("2017-06-18T11:01:00Z"),
                        "optimeDurableDate" : ISODate("2017-06-18T11:01:00Z"),
                        "lastHeartbeat" : ISODate("2017-06-18T11:01:04.522Z"),
                        "lastHeartbeatRecv" : ISODate("2017-06-18T11:01:05.695Z"),
                        "pingMs" : NumberLong(0),
                        "configVersion" : 2
                }
        ],
        "ok" : 1
...
$ 
$
$ # now stop everything
$ fg
make run-mongod-b
CTRL-C
$ 
$ fg
make run-mongod-a
CTRL-C
```
