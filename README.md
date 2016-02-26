# hubot-kaputskey
[![NPM version][npm-image]][npm-url] [![Build Status][travis-image]][travis-url] [![Coverage Status][coveralls-image]][coveralls-url]

A hubot script to clean out after de-provisioning

See [`src/kaputskey.coffee`](src/kaputskey.coffee) for full documentation.

## Installation

Expects https://github.com/hubot-scripts/hubot-auth project to be installed an for the 'kaputskey' role to be used.

In hubot project repo, run:

`npm install hubot-kaputskey --save`
`npm install hubot-auth --save`

Then add **hubot-kaputskey** to your `external-scripts.json`:

```json
[
  "hubot-kaputskey",
  "hubot-auth"
]
```

## Configuration

`katputskey` requires a bit of configuration to get everything working:

* HUBOT_AUTH_ADMIN - needs to be set for admins to set the 'kaputskey' role, for hipchat use the ID portion of the Jabber ID, note that changes to this will likely need a full redeploy of the hubot container.
* HUBOT_NAGIOSXI_HOST - IP of the machine that is running NagiosXI
* HUBOT_NAGIOSXI_USER - User that can ssh into the machine running NagiosXI
* HUBOT_NAGIOSXI_PASSWORD - Password of the user that can ssh into the machine running NagiosXI
* HUBOT_NAGIOSXI_UI_URL - URL of the User Interface for NagiosXI

## Sample Interaction

```
user1> hubot kaputskey server abc
hubot> Server Removal Request Acknowledged. Awaiting confirmation.
I need another approver to tell me:
hubot kaputskey confirm abc
```

```
user1> hubot kaputskey confirm abc
hubot> Sorry only those with the 'kaputskey' role can confirm that a server be removed
```

```
user1> hubot user1 has kaputskey role
hubot> user1: OK, Shell has the 'kaputskey' role.
```

```
user1>> hubot kaputskey confirm hubot_localhost
hubot> Beginning removal of hubot_localhost
 Successful removal of NagiosXI services on host hubot_localhost
 Successful removal of host hubot_localhost on NagiosXI 
 Successful reconfigure of host hubot_localhost on NagiosXI 
```



[npm-url]: https://www.npmjs.org/package/hubot-sumologic
[npm-image]: http://img.shields.io/npm/v/hubot-sumologic.svg?style=flat
[travis-url]: https://travis-ci.org/HearstAT/hubot-sumologic
[travis-image]: https://travis-ci.org/HearstAT/hubot-sumologic.svg?branch=master
[coveralls-url]: https://coveralls.io/r/HearstAT/hubot-sumologic
[coveralls-image]: http://img.shields.io/coveralls/HearstAT/hubot-sumologic/master.svg?style=flat