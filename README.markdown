# WebFaction Rails Stack
The accompanying shell script will automatically build and configure your own
private **Ruby on Rails/Merb** stack. It was written with
**[WebFaction](http://www.webfaction.com/?affiliate=rzownir)** users in
mind, but is more or less generic aside from a few minor details. Essentially,
the directories `$HOME/logs/user` and `$HOME/webapps/$APP_NAME` must exist
before running the script.

## What's Provided
* Ruby 1.8.7 (latest from the 1.8.7 subversion branch)
* RubyGems 1.3.1 (plus subsequent updates, if any)
* Gems: rails, merb, mongrel, mongrel\_cluster, thin, capistrano, termios,
  ferret, acts\_as\_ferret, god, sqlite3-ruby, mysql, and typo
* Git 1.6.1
* nginx 0.6.34 (with nginx-upstream-fair module for fair load balancing)
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
       "private application environment". It should be somewhere in your home
       directory. It has a default value of `$HOME/apps`. You could make it
       `$HOME`, but the home directory contains things that are better off
       separate. With a compartmentalized `PREFIX` like `$HOME/apps`, if you
       aren't happy with your setup, you could simply kill the monit, nginx,
       and thin processes, execute `rm -rf $HOME/apps` and start over fresh.
     * `APP_NAME` is the name of the app created in step one. The path
       `$HOME/webapps/$APP_NAME` should exist and contain at least a skeleton
       app. The default value for `APP_NAME` is `typo`.
     * `APP_PORT` is the port WebFaction assigned to the app created in step
       one. The default value is `4000`.
     * `MONIT_PORT` is the port WebFaction assigned to the app created in step
       two. The default value is `4002`.

## After Running the Script
If no unforeseen errors occurred, your rails app will be up and running in
production mode. Of course, `$HOME/webapps/$APP_NAME` must contain a
valid app for this to be true, even if it's just a skeleton. The working
default configuration sets up two thin instances listening on unix sockets
(mongrel does not have this capability) with nginx as the fair load balancing
reverse proxy. Monit watches nginx and the thin servers. A crontab entry
ensures that your setup springs back to life when the server has to reboot.
There are a couple of optional things you should do:

1. Inspect the nginx and monit conf files to learn how they work.
   Modify them as you like.
2. Generate ssl certificates and create an nginx https vhost following my
   example file if you have a dedicated IP address for https traffic.

## Feedback
Please leave a comment!
