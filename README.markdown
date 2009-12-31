# WebFaction Rails Stack
The accompanying shell script will automatically build and configure your own
private **Ruby on Rails** stack. It was written with **[WebFaction](http://www.webfaction.com/?affiliate=rzownir)**
users in mind, but is more or less generic aside from a few minor details.
Essentially, the directories `$HOME/logs/user` and `$HOME/webapps/$APP_NAME`
must exist before running the script.

## What's Provided
* Git 1.6.5.3
* Your choice of Ruby Enterprise Edition 1.8.7 - 2009.10 or Ruby 1.8.7 (latest
  from the 1.8.7 subversion branch)
* Latest RubyGems
* Gems: rack, rails, thin, passenger, capistrano, termios, sqlite3-ruby, mysql
* nginx 0.7.64 (with nginx-upstream-fair module for fair load balancing and
  passenger module)
* Monit 5.0.3
* Startup scripts and working default configuration files for monit and nginx

## Recent Changes
I have combined the two previous scripts, 'classic' and 'new'. You still have
the choice of running things with passenger or a thin cluster. However,
passenger is the default. You will have to follow a few extra steps to run a
thin stack. See below.

## Before Running the Script
1. Create a rails app from the WebFaction control panel. Leave the autostart
   box unchecked.
2. Create an app of type "custom application (listing on port)" from the
   WebFaction control panel. Name it monit.
3. Assign values to the four variables at the beginning of the script:
   `PREFIX`, `APP_NAME`, `APP_PORT`, and `MONIT_PORT`.
     * `PREFIX` is the installation path prefix. It is the location of your
       "private application environment". It should be somewhere in your home
       directory. It has a default value of `$HOME/apps`. You could make it
       `$HOME`, but the home directory contains things that are better off
       separate. With a compartmentalized `PREFIX` like `$HOME/apps`, if you
       aren't happy with your setup, you could simply kill the monit, nginx,
       and thin processes, execute `rm -rf $HOME/apps` and start over fresh.
     * `APP_NAME` is the name of the app created in step one. The path
       `$HOME/webapps/$APP_NAME` should exist and contain at least a skeleton
       app. The default value for `APP_NAME` is `blog`.
     * `APP_PORT` is the port WebFaction assigned to the app created in step
       one. The default value is `4000`.
     * `MONIT_PORT` is the port WebFaction assigned to the app created in step
       two. The default value is `4002`.
4. If you want to install Ruby 1.8.7 from the official subversion repository,
   edit line 12 of the script to read `export RUBYENTED=false`

## After Running the Script
If no unforeseen errors occurred, your rails app will be up and running in
production mode. Of course, `$HOME/webapps/$APP_NAME` must contain a
valid app for this to be true, even if it's just a skeleton.

By default passenger serves up the app. This can be easily changed so that two
thin instances are set up listening on unix sockets (mongrel does not have this
capability) with nginx as the fair load balancing reverse proxy. Monit watches
nginx (and the thin servers, if set up). A crontab entry ensures that your setup
springs back to life when the server is rebooted.

There are a couple of optional things you should do:

1. Inspect the nginx and monit conf files to learn how they work.
   Modify them as you like.
2. Generate ssl certificates and create an nginx https vhost following my
   example file if you have a dedicated IP address for https traffic.

## Switching to thin
If you want to use thin instead of passenger:

Move the thin nginx vhost into place.

	mv $PREFIX/etc/nginx/vhosts/$APP_NAME.conf $PREFIX/etc/nginx/vhosts/$APP_NAME-passenger.conf.example
	mv $PREFIX/etc/nginx/vhosts/$APP_NAME-thin.conf.example $PREFIX/etc/nginx/vhosts/$APP_NAME.conf

Move the thin monitrc file into place.

	mv $PREFIX/etc/monit/$APP_NAME.monitrc.example $PREFIX/etc/monit/$APP_NAME.monitrc

Quit all processes and restart monit...

	monit stop all
	monit quit
	monit

Prevent passenger processes from starting up with nginx. You have to manually
edit `$PREFIX/etc/nginx/nginx.conf`. Comment out the passenger directives:
`passenger_root` (most importantly), `passenger_ruby`, `passenger_max_pool_size`,
and any others you add.

Also be sure that the upstream thin directive is uncommented in the nginx.conf
file. I didn't comment it out to begin with because it doesn't do any harm if
it goes unused.

## Other Notes
Although the passenger stack uses less physical memory, the rss is often higher. This is because of multiple counting. Depending on how WebFaction meters memory usage, this could be a practical downside.

To compare your total rss vs your total private dirty rss (physical memory usage) run these commands:

	ps -u $USER -o rss | grep -v peruser | awk '{sum+=$1} END {printf("\n%.0fMB total RSS\n", sum/1024)}'
	(ps -u $USER -o pid | awk '{ print "grep Private_Dirty /proc/"$1"/smaps" }' | sh | awk '{ sum += $2 } END { printf("%.0fMB total Private Dirty RSS\n\n", sum/1024) }') 2>/dev/null

You will see that your actual physical memory usage is much smaller than what rss
reports.

## Extras
The script `extra.sh` contains some additional goodies:

* Memcached
* Erlang
* CouchDB

## Feedback
Please leave a blog comment!
