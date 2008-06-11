# [WebFaction Rails Stack](http://blog.princetonapps.com/articles/2008/04/11/ruby-on-rails-stack-on-webfaction)
The accompanying shell script will automatically build and configure your own
**Ruby on Rails/Merb** stack (private application environment). It was written
with **[WebFaction](http://www.webfaction.com/?affiliate=rzownir)** users in
mind, but is generally applicable apart from a few minor details. Basically,
the directories `$HOME/logs/user` and `$HOME/webapps/$APP_NAME` are expected
to exist before the script is executed.

## What's Provided
* Ruby 1.8.6 p114
* RubyGems 1.1.1
* Gems: rails, merb, mongrel, mongrel\_cluster, thin, capistrano, termios,
  ferret, acts\_as\_ferret, god, sqlite3-ruby, mysql, typo, and the latest
  eventmachine (to take advantage of unix sockets)
* Git 1.5.5.4
* Nginx 0.6.31 (with nginx-upstream-fair module for fair load balancing)
* Monit 4.10.1
* Startup scripts and working default configuration files for monit and nginx

## Before Running the Script
1. Create a rails app from the WebFaction control panel. Leave the autostart
   box unchecked.
2. Create an app of type "custom application (listing on port)" from the
   WebFaction control panel. Name it monit.
3. Assign values to the four variables at the beginning of the script:
   `PREFIX`, `APP_NAME`, `APP_PORT`, and `MONIT_PORT`.
     * `PREFIX` is the installation path prefix. It is the location of your
       "Private Application Environment". It should be somewhere in your home
       directory. It has a default value of `$HOME/apps`. You could make it
       `$HOME`, but the home directory contains directories like logs and
       webapps as well as hidden files and directories that are better off
       separate. With a compartmentalized `PREFIX` like `$HOME/apps`, if you
       aren't happy with your setup, you could simply kill the monit, nginx,
       and thin processes, execute `rm -rf $HOME/apps` and start over fresh.
     * `APP_NAME` is the name of the rails app created in the first step. The
       path `$HOME/webapps/$APP_NAME` should exist and contain at least a
       skeleton rails app. The default value for `APP_NAME` is `typo`.
     * `APP_PORT` is the port WebFaction assigned to the rails app created in
       the first step. The default value is `4000`.
     * `MONIT_PORT` is the port WebFaction assigned to you when you created the
       app in the second step. The default value is `4002`.

## After Running the Script
Assuming no unforeseen errors were encountered, your rails app will be up and
running in production mode. Of course, `$HOME/webapps/$APP_NAME` must contain a
valid app for this to be true, even if it's just a skeleton. The working
default configuration sets up two thin instances listening on unix sockets
(mongrel does not have this capability) with nginx as the fair load balancing
reverse proxy. Monit watches nginx and the thin cluster. There are a few thing
you should do manually:

1. Add the following line to your crontab (substituting `$PREFIX` for its
   literal value): `@reboot $PREFIX/etc/rc.d/monit start`
2. (Optional) Edit the nginx https vhost and generate ssl certificates.
3. Take a look at the nginx and monit conf files to see for yourself how they
   work. Modify them as you like.
