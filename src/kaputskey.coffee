# Description
#   A hubot script to clean out after de-provisioning
#
# Configuration:
#   HUBOT_AUTH_ADMIN - needs to be set for admins to set the 'kaputskey' role, for hipchat use the ID portion of the Jabber ID, note that changes to this will likely need a full redeploy of the hubot container.
#   HUBOT_NAGIOSXI_HOST - IP of the machine that is running NagiosXI
#   HUBOT_NAGIOSXI_USER - User that can ssh into the machine running NagiosXI
#   HUBOT_NAGIOSXI_PASSWORD - Password of the user that can ssh into the machine running NagiosXI
#   HUBOT_NAGIOSXI_UI_URL - URL of the User Interface for NagiosXI
#
# Commands:
#   hubot kaputskey server <server name> - request that the server be cleaned out of other systems
#   hubot kaputskey confirm <server name> - confirm that server can be cleaned out - must have 'kaputskey' role
#
# Notes:
#   For use in conjunction with the hubot-auth project.  The role of 'kaputskey' to confirm the clean out of a server. Initially only cleans out of NagiosXI
#   See: https://assets.nagios.com/downloads/nagiosxi/docs/Automated_Host_Management.pdf
#
# Author:
#   atat@hearst.com

SSH = require("simple-ssh");

nagiosXIhost = process.env.HUBOT_NAGIOSXI_HOST
nagiosXIuser = process.env.HUBOT_NAGIOSXI_USER
nagiosXIpass = process.env.HUBOT_NAGIOSXI_PASSWORD
nagiosXIuiURL = process.env.HUBOT_NAGIOSXI_UI_URL

module.exports = (robot) ->

  unless process.env.HUBOT_AUTH_ADMIN?
    return robot.logger.error "HUBOT_NAGIOSXI_HOST env var not set."
  unless process.env.HUBOT_NAGIOSXI_HOST?
    return robot.logger.error "HUBOT_NAGIOSXI_HOST env var not set."
  unless process.env.HUBOT_NAGIOSXI_USER?
    return robot.logger.error "HUBOT_NAGIOSXI_USER env var not set."
  unless process.env.HUBOT_NAGIOSXI_PASSWORD?
    return robot.logger.error "HUBOT_NAGIOSXI_PASSWORD env var not set."
  unless process.env.HUBOT_NAGIOSXI_UI_URL?
    return robot.logger.error "HUBOT_NAGIOSXI_UI_URL env var not set."

  robot.respond /kaputskey server (.+)/i, (msg) ->
    nagios_host = msg.match[1]
    robot_name = robot.alias or robot.name or 'hubot'
    robot.brain.set 'currentRequest', nagios_host
    console.log "#{msg.message.user.name} (#{msg.message.user.email}) requested that #{nagios_host} be removed from nagios"
    msg.send('Server Removal Request Acknowledged. Awaiting confirmation.\n' +
               'I need another approver to tell me:\n' +
               robot_name + ' kaputskey confirm ' + nagios_host );

  robot.respond /kaputskey confirm (.+)/i, (msg) ->
    nagios_host = msg.match[1]
    robot_name = robot.alias or robot.name or 'hubot'
    current_request = robot.brain.get 'currentRequest'
    console.log "#{msg.user.name} (email #{msg.user.email}) confirmed that #{nagios_host} be removed from nagios"
    if current_request != nagios_host
      msg.send(nagios_host + ' was not the last server requested to be removed. \n' +
                  'Someone will need to request this first: \n' +
                  robot_name + ' kaputskey server ' + nagios_host );
      return

    if robot.auth.hasRole(msg.envelope.user, "kaputskey")
      msg.send "Beginning removal of #{nagios_host}"
      
      deleteservice = "cd /usr/local/nagiosxi/scripts/;sudo ./nagiosql_delete_service.php --config=#{nagios_host}"
      deletehost = "cd /usr/local/nagiosxi/scripts/;sudo ./nagiosql_delete_host.php --host=#{nagios_host}"
      reconfigurenagios = "cd /usr/local/nagiosxi/scripts/;sudo ./reconfigure_nagios.sh"

      ssh = new SSH(
        host: nagiosXIhost
        user: nagiosXIuser
        pass: nagiosXIpass)

      ssh.on 'error', (err) ->
        msg.reply err
        ssh.end()
        return

      ssh.exec(deleteservice,
        pty: true
        out: (stdout) ->
          #msg.reply stdout 
          return
        exit: (code) ->
          code_message = switch code
            when 0 then "Successful removal of services on host #{nagios_host}"
            when 1 then "Could not remove services on host #{nagios_host} ERROR: Usage error - ensure host exists at #{nagiosXIuiURL}"
            when 2 then "Could not remove services on host #{nagios_host} ERROR: DB connection failed"
            when 3 then "Could not remove services on host #{nagios_host} ERROR: Dependent relationship"
          msg.reply code_message
          console.log "Exit code: #{code} on delete services for #{nagios_host} meaning #{code_message})"
          return
        err: (stderr) ->
          msg.reply(stderr)
          ssh.end()
          return
      ).exec(deletehost,
        pty: true
        out: (stdout) ->
          #msg.reply stdout 
          return
        exit: (code) ->
          code_message = switch code
            when 0 then "Successful removal of host #{nagios_host}"
            when 1 then "Could not remove host #{nagios_host} ERROR: Usage error - ensure host exists at #{nagiosXIuiURL}"
            when 2 then "Could not remove host #{nagios_host} ERROR: DB connection failed"
            when 3 then "Could not remove host #{nagios_host} ERROR: Dependent relationship"
          msg.reply code_message
          console.log "Exit code: #{code} on delete host for #{nagios_host} meaning #{code_message})"
          return
        err: (stderr) ->
          msg.reply(stderr)
          ssh.end()
          return
      ).exec(reconfigurenagios,
        pty: true
        out: (stdout) ->
          #msg.reply stdout 
          return
        exit: (code) ->
          code_message = switch code
            when 0 then "Successful reconfigure of host #{nagios_host}"
            when 1 then "Could not reconfigure host #{nagios_host} ERROR: config verification failed"
            when 2 then "Could not reconfigure host #{nagios_host} ERROR: nagiosql login failed"
            when 3 then "Could not reconfigure host #{nagios_host} ERROR: nagiosql import failed"
            when 4 then "Could not reconfigure host #{nagios_host} ERROR: reset_config_perms failed"
            when 5 then "Could not reconfigure host #{nagios_host} ERROR: nagiosql_exportall.php failed (write configs failed)"
            when 6 then "Could not reconfigure host #{nagios_host} ERROR: /etc/init.d/nagios restart failed"
            when 7 then "Could not reconfigure host #{nagios_host} ERROR: db_connect failed"
          msg.reply code_message
          console.log "Exit code: #{code} on reconfigure nagios for #{nagios_host} meaning #{code_message})"
          return
        err: (stderr) ->
          msg.reply(stderr)
          ssh.end()
          return
      ).start()
    else
      msg.send "Sorry only those with the 'kaputskey' role can confirm that a server be removed"
