# IronGrid

[![Code Climate](https://codeclimate.com/repos/533a34da695680591d00046a/badges/1fffa66023d44fe34379/gpa.png)](https://codeclimate.com/repos/533a34da695680591d00046a/feed)

## Running

### Requirements

* JRuby 1.7.10
* PostgreSQL 9.3.2 or higher
* Redis
* Elasticsearch 1.0 or higher (`brew install elasticsearch`)

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

RAILS_ENV="production" DB_POOL=5 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --1.9 -S bundle exec rake service:boot_all --trace

### Crawls - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,2 -q crawl_images,1 -q scrapes,1 -c 10 2>&1 | logger -t sidekiq

### Crawls - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,2 -q crawl_images,1 -q scrapes,1 -c 10 2>&1 | logger -t sidekiq

### Crawl images - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawl_images,2 -q crawls,1 -q scrapes,1 -c 10 2>&1 | logger -t sidekiq

### Crawl images - small
RAILS_ENV="production" DB_POOL=2 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawl_images,2 -q crawls,1 -q scrapes,1 -c 10 2>&1 | logger -t sidekiq

### Fast DB ip-10-118-14-33 - medium
RAILS_ENV="production" DB_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q fast_db,2 -q scrapes,1 -c 25 2>&1 | logger -t sidekiq

### Slow DB ip-10-118-14-33 - medium
RAILS_ENV="production" DB_POOL=30 REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q slow_db,2 -q scrapes,1 -c 25 2>&1 | logger -t sidekiq

### Crawls, crawl images, slow db - medium
RAILS_ENV="production" DB_POOL=30 REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,1 -q crawl_images,1 -q slow_db,1 -q scrapes,1 -c 25 2>&1 | logger -t sidekiq


### Emergency xlarge:
RAILS_ENV="production" DB_POOL=50 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx3584m -J-Xms3584m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q fast_db -c 50 2>&1 | logger -t sidekiq

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

