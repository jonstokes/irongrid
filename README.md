# IronGrid

[![Code Climate](https://codeclimate.com/repos/533a34da695680591d00046a/badges/1fffa66023d44fe34379/gpa.png)](https://codeclimate.com/repos/533a34da695680591d00046a/feed)

# Boot grid

## Services ip-10-29-184-221
RAILS_ENV="production" DB_POOL=5 daemon -U -r --stdout=syslog -n sidekiq_daemon -D /home/bitnami/irongrid -- jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --1.9 -S bundle exec rake service:boot_all --trace

RAILS_ENV="production" DB_POOL=5 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --1.9 -S bundle exec rake service:boot_all --trace

## Logs ip-10-28-115-24
RAILS_ENV="production" DB_POOL=10 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q logs -c 10 2>&1 | logger -t sidekiq

## Crawls ip-10-157-49-96
RAILS_ENV="production" DB_POOL=1 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,2 -q crawl_images -c 10 2>&1 | logger -t sidekiq

## Crawls ip-10-235-6-24
RAILS_ENV="production" DB_POOL=1 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawl_images,2 -q crawls -c 10 2>&1 | logger -t sidekiq

## Crawls ip-10-182-164-47
RAILS_ENV="production" DB_POOL=1 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawl_images,2 -q crawls -c 10 2>&1 | logger -t sidekiq

## Fast DB ip-10-118-14-33
RAILS_ENV="production" DB_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q fast_db -c 25 2>&1 | logger -t sidekiq

## Crawls ip-10-118-14-33
RAILS_ENV="production" DB_POOL=1 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,2 -q crawl_images -c 25 2>&1 | logger -t sidekiq

## Emergency xlarge:
RAILS_ENV="production" DB_POOL=50 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx3584m -J-Xms3584m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q fast_db -c 50 2>&1 | logger -t sidekiq

## Memory

To boot with extra memory:

jruby -J-Xmn512m -J-Xms10240m -J-Xmx10240m -J-server --1.9 -S bundle exec rails c

Rake with extra memory:
RAILS_ENV="staging" jruby -J-Xmn512m -J-Xms10240m -J-Xmx10240m -J-server --1.9 -S bundle exec rake affiliate_setup --trace


# Bitnami image prod enviroment

## Install software
sudo apt-get update
sudo apt-get autoremove
sudo apt-get install git tmux daemon ack htop

## Set up remote syslog
# per http://help.papertrailapp.com/kb/configuration/configuring-remote-syslog-from-unixlinux-and-bsdos-x
sudo vim /etc/rsyslog.conf

*.*                                         @logs.papertrailapp.com:20063

sudo service rsyslog restart

## Git setup
git clone http://github.com/jonstokes/irongrid.git
cd irongrid/
git checkout master
sudo bundle install  # don't forget the sudo!

mkdir tmp/
cp config/database.example.yml config/database.yml
git config credential.helper store

# To set up dev environment on bitnami
## Postgresql
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
#https://gist.github.com/wingdspur/2026107
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.9.deb
sudo dpkg -i elasticsearch-0.90.9.deb

# Dev env on Mac
Install VirtualBox
Download latest Bitnami image for jruby
Import jruby image into Virtual Box
Set up networking as bridge adapter so that the host gets an ip

Install fuse4x and sshfs

## Fuse4x
brew install sshfs
brew install fuse4x
brew install fuse4x-kext

vagrant plugin install vagrant-sshfs # May not be necessary

