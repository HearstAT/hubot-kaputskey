# Description
#   A hubot script to clean out after de-provisioning
#
# Configuration:
#   HUBOT_AUTH_ADMIN - needs to be set for admins to set the 'kaputsky' role, for hipchat use the ID portion of the Jabber ID, note that changes to this will likely need a full redeploy of the hubot container.
#   HUBOT_NAGIOSXI_HOST - IP of the machine that is running NagiosXI
#   HUBOT_NAGIOSXI_USER - User that can ssh into the machine running NagiosXI
#   HUBOT_NAGIOSXI_PASSWORD - Password of the user that can ssh into the machine running NagiosXI
#
# Commands:
#   hubot kaputsky server <server name> - request that the server be cleaned out of other systems
#   hubot kaputsky confirm <server name> - confirm that server can be cleaned out - must have 'kaputsky' role
#
# Notes:
#   For use in conjunction with the hubot-auth project.  The role of 'kaputsky' to confirm the clean out of a server
#
# Author:
#   atat@hearst.com

SSH = require("simple-ssh");

nagiosXIhost = process.env.HUBOT_NAGIOSXI_HOST
nagiosXIuser = process.env.HUBOT_NAGIOSXI_USER
nagiosXIpass = process.env.HUBOT_NAGIOSXI_PASSWORD

module.exports = (robot) ->
  robot.respond /kaputsky server (.+)/i, (msg) ->
    robot_name = robot.alias or robot.name or 'hubot'
    robot.brain.set 'currentRequest', msg.match[1]
    msg.send('Server Removal Request Acknowledged. Awaiting confirmation.\n' +
               'I need another approver to tell me:\n' +
               robot_name + ' kaputsky confirm ' + msg.match[1] );

  robot.respond /kaputsky confirm (.+)/i, (msg) ->
    robot_name = robot.alias or robot.name or 'hubot'
    current_request = robot.brain.get 'currentRequest'
    if current_request != msg.match[1]
      msg.send(#{msg.match[1] + ' was not the last server requested to be removed. \n' +
                  'Someone will need to request this first: \n' +
                  robot_name + ' kaputsky server ' + msg.match[1] );
      return

    if robot.auth.hasRole(msg.envelope.user, "kaputsky")
      msg.send "Beginning removal of #{msg.match[1]}"
      
      changedir = "cd /usr/local/nagiosxi/scripts/;ls"
      deleteservice = "cd /usr/local/nagiosxi/scripts/;echo ./nagiosql_delete_service.php --config=#{msg.match[1]}"
      deletehost = "cd /usr/local/nagiosxi/scripts/;echo ./nagiosql_delete_host.php –-host=#{msg.match[1]}"
      reconfigurenagios = "cd /usr/local/nagiosxi/scripts/;echo ./reconfigure_nagios.sh"
      
      ssh = new SSH(
        host: nagiosXIhost
        user: nagiosXIuser
        pass: nagiosXIpass)

      ssh.on 'error', (err) ->
        msg.reply err
        ssh.end()
        return

      ssh.exec(changedir,
        out: (stdout) ->
          msg.reply "Changing to correct directory #{stdout}"
          return
        exit: (code) ->
          msg.reply 'Exit code :' + code
          return
        err: (stderr) ->
          msg.reply(stderr)
          ssh.end()
          return
      ).exec(deleteservice,
        out: (stdout) ->
          msg.reply stdout 
          return
        exit: (code) ->
          code_message = switch code
            when 0 then "Successful removal of services on host #{msg.match[1]}"
            when 1 then "Could not remove services on host #{msg.match[1]} ERROR: Usage error"
            when 2 then "Could not remove services on host #{msg.match[1]} ERROR: DB connection failed"
            when 3 then "Could not remove services on host #{msg.match[1]} ERROR: Dependent relationship"
          msg.reply code_message
          return
        err: (stderr) ->
          msg.reply(stderr)
          ssh.end()
          return
      ).exec(deletehost,
        out: (stdout) ->
          msg.reply stdout 
          return
        exit: (code) ->
          code_message = switch code
            when 0 then "Successful removal of host #{msg.match[1]}"
            when 1 then "Could not remove host #{msg.match[1]} ERROR: Usage error"
            when 2 then "Could not remove host #{msg.match[1]} ERROR: DB connection failed"
            when 3 then "Could not remove host #{msg.match[1]} ERROR: Dependent relationship"
          msg.reply code_message
          return
        err: (stderr) ->
          msg.reply(stderr)
          ssh.end()
          return
      ).exec(reconfigurenagios,
        out: (stdout) ->
          msg.reply stdout 
          return
        exit: (code) ->
          msg.reply 'Exit code :' + code
          return
        err: (stderr) ->
          msg.reply(stderr)
          ssh.end()
          return
      ).start()

    else
      msg.send "Sorry only those with the 'kaputsky' role can confirm that a server be removed"
