# WebFaction Rails Stack
The accompanying shell script will automatically build and configure your own
private **Ruby on Rails** stack. It was written with
**[WebFaction](http://www.webfaction.com/?affiliate=rzownir)** users in
mind, but is more or less generic aside from a few minor details. Essentially,
the directories `$HOME/logs/user` and `$HOME/webapps/$APP_NAME` must exist
before running the script.

There are now two stack scripts, the classic one, webfaction.sh, and a new one,
webfaction-alt.sh. The classic one is a monit/nginx/ruby 1.8.7 MRI/thin stack
and the new one is an nginx/ruby enterprise edition 1.8.6/passenger stack. The
classic script includes passenger and the passenger nginx module in case you
want to give it a whirl. Now that passenger works with nginx, it has become the
clear choice. It is certainly simpler. However, although the new stack uses less
physical memory, the rss is often higher. This is because of multiple counting.
Depending on how WebFaction meters memory usage, this could be a practical
downside.

To compare your total rss vs your total private dirty rss (physical memory usage) run these commands:

	ps -u $USER -o rss | grep -v peruser | awk '{sum+=$1} END {printf("\n%.0fMB total RSS\n", sum/1024)}'
	(ps -u $USER -o pid | awk '{ print "grep Private_Dirty /proc/"$1"/smaps" }' | sh | awk '{ sum += $2 } END { printf("%.0fMB total Private Dirty RSS\n\n", sum/1024) }') 2>/dev/null

You will see that your actual physical memory usage is much smaller than what rss
reports.

# Classic Script
## What's Provided
* Ruby 1.8.7 (latest from the 1.8.7 subversion branch)
* Latest RubyGems
* Gems: rails, thin, capistrano, termios, god, sqlite3-ruby, mysql, typo, and
  passenger
* Git 1.6.2.4
* nginx 0.6.36 (with nginx-upstream-fair module for fair load balancing and passenger module)
* Monit 5.0
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
       app. The default value for `APP_NAME` is `blog`.
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

# New Script
## What's Provided
* Ruby Enterprise Edition 1.8.6 - 20090201
* Latest RubyGems
* Gems: rack, rails, mysql, sqlite3-ruby, passenger, thin, capistrano, termios
* Git 1.6.2.4
* nginx 0.6.36 (with nginx-upstream-fair module for fair load balancing and passenger module)
* Startup scripts and working default configuration files for nginx

## Before Running the Script
Follow Steps 1 and 3 for the classic script, and ignore monit related
information in Step 3.

# Feedback
Please leave a blog comment!
