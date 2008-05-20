#WebFaction Rails Stack

The accompanying shell script will automatically build and configure your own Ruby on Rails/Merb stack. It was written with WebFaction users in mind, but is generally applicable apart from a few minor details. Basically, the directories $HOME/logs/user and $HOME/webapps/$APP_NAME should exist before the script is executed.

Before executing the script, you need to edit four variable assignments at the beginning of the script:

	* PREFIX - The installation path prefix.
	* APP_NAME - The name of your rails app.
	* APP_PORT - The port number assigned to the app specified above.
	* MONIT_PORT - The port number to use for monit. Create a "Custom app (listening on port)" named "monit" from the WebFaction Control Panel and use the port assigned.

The application environment consists of:

	* Ruby 1.8.6 p114
	* RubyGems 1.1.1
	* Gems: rails, merb, mongrel, mongrel\_cluster, thin, capistrano, termios, ferret, acts\_as\_ferret, god, sqlite3-ruby, mysql, typo, and the latest eventmachine (to take advantage of unix sockets)
	* Git 1.5.5.1
	* Nginx 0.6.31 (with nginx-upstream-fair module for fair load balancing)
	* Monit 4.10.1
	* Working configuration files for monit and nginx tailored to your app.

When the script is finished, your app should be up and running in production (assuming that $HOME/webapps/$APP_NAME contains a valid app). The working example configuration sets up two thin instances listening on unix sockets (mongrel does not have this capability) with nginx as the fair load balancing reverse proxy. Monit watches nginx and the thin cluster.

You will want to start monit at reboot with an entry in your crontab file. As it stands now, if a zombie nginx pid file exists, nginx will not start on reboot. It is therefore essential to remove any zombie pid files prior to starting monit on reboot. This can be accomplished by adding a line to your crontab before the line that starts monit. See the comments at the end of the script for more information.