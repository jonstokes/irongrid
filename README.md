# IronGrid

[![Code Climate](https://codeclimate.com/repos/533a34da695680591d00046a/badges/1fffa66023d44fe34379/gpa.png)](https://codeclimate.com/repos/533a34da695680591d00046a/feed)

## Running

### Requirements

* JRuby 1.7.10
* PostgreSQL 9.3.2 or higher
* Redis
* Elasticsearch 1.0 or higher (`brew install elasticsearch`)

### About IronGrid

IronGrid uses stretched.io to crawl retail websites for product
listings, and it dumps those listings into a database and search index. 

The platform takes site adapter
information from the `ironsights-sites` repo, including info that has been registered
with stretched.io already, and uses it to crawl retail sites. It does a
bit of cleanup and metadata extraction on the listings that it gets from
stretched.io before writing those listings to the database.

![IronSights and stretched.io](http://scoperrific-site.s3.amazonaws.com/irongrid.png)

In the diagram above, you can see that we us the `validator` app to
register our sites with stretched.io. (We can also use the `irongrid`
repo to do this, if needed.) Once a site is registered, we can populate
its session queue with sessions. After the session queue is populated,
stretched.io will start to run those sessions, and will put the
resulting listing objects that it finds into the site's object queue.

When IronGrid detects that listing objects are showing up in the object
queue, it'll pull them, do some more work on them, and update the
database accordingly.

Note that the above is a vastly simplified version of what actually goes
on, but it provides a good place to start.

In general, I've tried to achieve the following division of labor with
the above arrangement:

1. Stretched.io -- this is a generic web crawling platform that can
   crawl any type of page, and create a set of JSON objects from it.
2. IronGrid -- this platform uses stretched.io to crawl product listings
   from retail sites. So it embodies some domain-specific knowldge about
listings, products, site catalog pages, shipping costs, and so on. It could theoretically be 
used to crawl retail sites in any domain, as I'ved tried (but not yet
completely succeeded) in pulling out any firearm-specific code from it.
3. Ironsights-sites -- this repo is supposed to distill all of the
   firearm-specific knowlege into one place. So IronGrid uses the
scripts and YAML in this repo to do things like identify calibers,
bullet weights, and so on.

So you can see that IronGrid uses stretched.io to crawl retail sites and
pull product listings, and ironsights-sites configures and uses both
IronGrid and stretched.io to specifically crawl firearm-related websites
and extract relevant data about products from the listings.

A different repo similar to ironsights-sites could configure and use
both stretched.io and IronGrid to crawl other types of retail sites,
like survival food, fly fishing, etc.

### Setup

1. Clone the repo
2. `bundle install`
3. `cp config/application.example.yml config/application.yml`
4. `cp config/database.example.yml config/database.yml` and modify to
   use the JDBC url settings from the heroku pg instance attached to the
   the app `irongrid` on heroku.


## Monitoring

The IronGrid production dashboard is available at http://irongrid-dashboard.herokuapp.com/

For the staging environment, the dashboard is at http://irongrid-dashboard-staging.herokuapp.com/

# Misc Deployment Notes

## Boot sidekiq instances

### Services ip-10-29-184-221
RAILS_ENV="production" DB_POOL=5 daemon -U -r --stdout=syslog -n sidekiq_daemon -D /home/bitnami/irongrid -- jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --1.9 -S bundle exec rake service:boot_all --trace

RAILS_ENV="production" REDIS_POOL=20 DB_POOL=5 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --1.9 -S bundle exec rake service:boot_all --trace

### Crawls - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q stretched,2 -q crawl_images,1 -q crawls,1 -c 10 2>&1 | logger -t sidekiq

### Crawls - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q stretched,2 -q crawl_images,1 -q crawls,1 -c 10 2>&1 | logger -t sidekiq

### Crawl images - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawl_images,2 -q stretched,1 -q crawls,1 -c 10 2>&1 | logger -t sidekiq

### Crawl images - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawl_images,2 -q stretched,1 -q crawls,1 -c 10 2>&1 | logger -t sidekiq

### Fast DB ip-10-118-14-33 - medium
RAILS_ENV="production" DB_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -r /home/bitnami/irongrid -q fast_db -c 25 2>&1 | logger -t sidekiq

### Slow DB ip-10-118-14-33 - medium
RAILS_ENV="production" DB_POOL=30 REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q slow_db,2 -q crawls,1 -q stretched,1 -c 25 2>&1 | logger -t sidekiq

### Crawls, crawl images, slow db - medium
RAILS_ENV="production" DB_POOL=30 REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,2 -q crawl_images,3 -q slow_db,1 -q stretched,1 -c 25 2>&1 | logger -t sidekiq

### Emergency xlarge:
RAILS_ENV="production" DB_POOL=10 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx5376m -J-Xms5376m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q utils -c 5

### xlarge reindex task:
RAILS_ENV="production" DB_POOL=50 LISTINGS_INDEX="listings" jruby -Xcompile.invokedynamic=true -J-server -J-Xmx3584m -J-Xms3584m -S bundle exec rake tire:index:seed --trace


## Bitnami production enviroment setup

### Install software
sudo apt-get update
sudo apt-get autoremove
sudo apt-get install git tmux daemon ack htop

### Set up remote syslog
per http://help.papertrailapp.com/kb/configuration/configuring-remote-syslog-from-unixlinux-and-bsdos-x

sudo vim /etc/rsyslog.conf

*.*                                         @logs.papertrailapp.com:20063

sudo service rsyslog restart

### Git setup
git clone http://github.com/jonstokes/irongrid.git
cd irongrid/
git checkout master
sudo bundle install  # don't forget the sudo!

mkdir tmp/
cp config/database.example.yml config/database.yml
git config credential.helper store

## Bitnami development enviroment setup
### Postgresql
For pg install, see here:
http://www.postgresql.org/download/linux/ubuntu/

Create the file /etc/apt/sources.list.d/pgdg.list, and add a line for the repository

deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main

Import the repository signing key, and update the package lists

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  sudo apt-key add -
sudo apt-get update

sudo apt-get install postgresql-9.3 postgresql-contrib-9.3

(http://www.filippozanella.com/blog/setting-up-postgresql-on-ubuntu-precise12-04-ruby-on-rails-ror3-2-11-ruby1-9-3-and-heroku-gem2-34-0/)

sudo -u postgres psql postgres
\password # hit enter and leave this blank
\q

sudo -u postgres createdb irongrid_development
sudo -u postgres createdb irongrid_test

## Elasticsearch
sudo apt-get install openjdk-7-jre-headless -y

per https://gist.github.com/wingdspur/2026107

wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.9.deb
sudo dpkg -i elasticsearch-0.90.9.deb

## Phantomjs
https://coderwall.com/p/rs63ea

cd /usr/local/share
sudo wget sudo wget https://phantomjs.googlecode.com/files/phantomjs-1.9.0-linux-x86_64.tar.bz2
sudo tar xjf phantomjs-1.9.0-linux-x86_64.tar.bz2
sudo ln -s /usr/local/share/phantomjs-1.9.0-linux-x8664/bin/phantomjs /usr/local/share/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.0-linux-x8664/bin/phantomjs /usr/local/bin/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.0-linux-x86_64/bin/phantomjs /usr/bin/phantomjs
phantomjs --version

sudo rm /usr/local/share/phantomjs
sudo rm /usr/local/bin/phantomjs
sudo rm /usr/bin/phantomjs
cd /usr/local/share
sudo wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-x86_64.tar.bz2
sudo tar xjf phantomjs-1.9.7-linux-x86_64.tar.bz2
sudo ln -s /usr/local/share/phantomjs-1.9.7-linux-x8664/bin/phantomjs /usr/local/share/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.7-linux-x8664/bin/phantomjs /usr/local/bin/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.7-linux-x86_64/bin/phantomjs /usr/bin/phantomjs
phantomjs --version


