# IronGrid

[![Code Climate](https://codeclimate.com/repos/533a34da695680591d00046a/badges/1fffa66023d44fe34379/gpa.png)](https://codeclimate.com/repos/533a34da695680591d00046a/feed)

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

## How IronGrid crawls a site

IronGrid crawls a site in two phases:

1. The *catalog phase* is when the platform takes a set of seed links
   that are given in a site's adapter file (under `sessions`) and uses
them to compile a list of product pages to be crawled. These links are
usually what I call "catalog pages", i.e. they're pages with links to
multiple products. Here's a [catalog page for Bud's](http://www.budsgunshop.com/catalog/index.php/cPath/21_0), for instance.
2. The *listings phase* is when the site's session queue is populated
   with links to actual product pages, and stretched is crawling those
pages, extracting listings, and pushing the results to the correct
object queue so that IronGrid can consume them and put them into the
database.

### Catalog Phase, Step 1: Populate Session Queue

![IronSights and stretched.io](http://scoperrific-site.s3.amazonaws.com/catalog-phase-1.png)

IronGrid's PopulateSessionQueueWorker takes the `session`s defined in the
site's adapter code and pushes them into the site's session queue on
stretched.


### Catalog Phase, Step 2: Pull Product Links

![IronSights and stretched.io](http://scoperrific-site.s3.amazonaws.com/catalog-phase-2.png)

As product links begin to show up in the site's product_link queue,
PullProductLinksWorkers will spawn and pop them and push them into a link
set. 

### Catalog Phase, Step 3: Prune, Refresh, Push
![IronSights and stretched.io](http://scoperrific-site.s3.amazonaws.com/catalog-phase-3.png)

Once stretched has finished running all of the sessions that were
pushed into the session queue in step 1, and the product_link queue is
empty, there will be a whole bunch of links in the link set. Some of
those links will be new links that the system has never seen before,
others will be links to product pages that were just recently updated
and therefore don't need to be crawled again, and others will be links
to product pages that are stale and need to be re-crawled. The
platform's job now is to sort out which is which, and that is the
purpose of Step 2.

*Note*: The link set (called a `IronCore::LinkMessageQueue` in the code base for
legacy reasons) is an actual redis set, meaning that all of the links in it
are unique. There are no dupes.


First, the PruneLinksWorker goes through each link in the link set and
sniffs it for freshness (i.e. its `updated_at` timestamp is within a certain window). 
If it's fresh, it gets deleted from the set (to be re-added
and re-crawled another day). If it's stale it stays. And if it's a brand
new link it stays.

Once the PruneLinksWorker has ensured that all of the links in the link
set are actually in need of (re)crawling, the RefreshLinksWorker checks
the database for stale links for that site and dumps them into the link
set, as well.

Finally, the PushProductLinksWorker clears out the link set by creating
new stretched.io sessions for all of the links in it and pushing those sessions back to the session queue.
At this point, all of the sessions in the session queue will
(ideally) be product pages, so now the listings phase begins.

### Listings Phase
![IronSights and stretched.io](http://scoperrific-site.s3.amazonaws.com/listing-phase.png)

In the listings phase, IronGrid's PullListingsWorker clears out the
listings object queue and writes any valid listings to the database. It
also deletes any invalid or `not_found` listings, does some final
metadata extraction, and handles a few other chores.

## Setup

1. Clone the repo
2. `bundle install`
3. `cp config/application.example.yml config/application.yml`
4. `cp config/database.example.yml config/database.yml` and modify to
   use the JDBC url settings from the heroku pg instance attached to the
   the app `irongrid` on heroku.


## Monitoring

The IronGrid production dashboard is available at http://irongrid-dashboard.herokuapp.com/

For the staging environment, the dashboard is at http://irongrid-dashboard-staging.herokuapp.com/

# Bring up stretched.io for a clean boot

Bring down grid

	RAILS_ENV=production rails c: 
	VALIDATOR_REDIS_POOL.with { |c| c.flushdb }
	STRETCHED_REDIS_POOL.with { |c| c.flushdb }
	IRONGRID_REDIS_POOL.with { |c| c.flushdb }
	Sidekiq.redis { |c| c.flushdb }

Load irongrid loadables

	## /validator
	RAILS_ENV=production bundle exec rake site:add_new
	RAILS_ENV=production bundle exec rake stretched:register_all

	## /stretched-node
	RAILS_ENV=production bundle exec rake user:create_all

	## /irongrid
	RAILS_ENV=production bundle exec rake site:load_scripts



# Misc Deployment Notes

RAILS_ENV="production" REDIS_POOL=50 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m --2.0 -S bundle exec sidekiq -v -r /home/bitnami/stretched-node -q stretched -c 50 2>&1 | logger -t sidekiq

RAILS_ENV="production" REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m --2.0 -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,10 -q crawl_images,2 -q db_slow_high,1 -q db_slow_low,1 -c 25  2>&1 | logger -t sidekiq
RAILS_ENV="production" REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m --2.0 -S bundle exec sidekiq -v -r /home/bitnami/irongrid  -q db_slow_high,10 -q db_slow_low,5 -q crawls,1 -q crawl_images,2 -c 25  2>&1 | logger -t sidekiq


RAILS_ENV="production" REDIS_POOL=20 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m --2.0 -S bundle exec rake service:boot --trace

RAILS_ENV="production" REDIS_POOL=20 DB_POOL=5 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --2.0 -S bundle exec rake service:boot_all --trace


RAILS_ENV="production" REDIS_POOL=20 DB_POOL=5 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --2.0 -S bundle exec rails c


curl -O https://www.loggly.com/install/configure-linux.sh
sudo bash configure-linux.sh -a firetop -u jonstokes

wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.1.deb



daemon -U -r --stdout=syslog -n validator -D /home/bitnami/validator -- jruby --2.0 -S bundle exec rails s

daemon -U -r --stdout=syslog -n stretched-services -D /home/bitnami/stretched -- jruby --2.0 -S bundle exec rake service:boot_all

daemon -U -r --stdout=syslog -n stretched-sidekiq -D /home/bitnami/stretched -- jruby --2.0 -S bundle exec sidekiq -r /home/bitnami/stretched-node -q stretched

daemon -U -r --stdout=syslog -n irongrid-services -D /home/bitnami/irongrid -- jruby --2.0 -S bundle exec rake service:boot_all

daemon -U -r --stdout=syslog -n irongrid-sidekiq -D /home/bitnami/irongrid -- jruby --2.0 -S bundle exec sidekiq -r /home/bitnami/irongrid -q scrapes


## Staging deploy

RAILS_ENV="staging" REDIS_POOL=3 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m --2.0 -S bundle exec rake service:boot --trace 2>&1 | logger -t sidekiq
RAILS_ENV="staging" REDIS_POOL=3 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m --2.0 -S bundle exec sidekiq -v -r /home/bitnami/stretched-node -q stretched -c 5 2>&1 | logger -t sidekiq
RAILS_ENV="staging" REDIS_POOL=3 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m --2.0 -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q scrapes -c 5 2>&1 | logger -t sidekiq


## Boot sidekiq instances

### Services ip-10-29-184-221

	RAILS_ENV="production" DB_POOL=5 daemon -U -r --stdout=syslog -n sidekiq_daemon -D /home/bitnami/irongrid -- jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --1.9 -S bundle exec rake service:boot_all --trace

	RAILS_ENV="production" REDIS_POOL=20 DB_POOL=5 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1536m -J-Xms1536m --1.9 -S bundle exec rake service:boot_all --trace

### Crawls, crawl images, slow db, scrapes - medium

	RAILS_ENV="production" REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q scrapes,10 -q crawls,4 -q crawl_images,2 -c 25 2>&1 | logger -t sidekiq

### Db, scrapes, crawls - medium

	RAILS_ENV="production" REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q scrapes,10 -q db_slow_high,4 -q db_slow_low,3 -q crawl_images,2 -c 25 2>&1 | logger -t sidekiq

	RAILS_ENV="production" REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q db_slow_high -q db_slow_low -q crawls -q crawl_images -c 25 2>&1 | logger -t sidekiq

### Emergency xlarge:

	RAILS_ENV="production" DB_POOL=10 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx5376m -J-Xms5376m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q utils -c 5

	RAILS_ENV="production" REDIS_POOL=30 jruby -Xcompile.invokedynamic=true -J-server -J-Xmx1792m -J-Xms1792m -S bundle exec sidekiq -v -r /home/bitnami/irongrid -q crawls,4 -c 25 2>&1 | logger -t sidekiq

## Bitnami production enviroment setup

### Install software

	$ sudo apt-get update
	$ sudo apt-get autoremove
	$ sudo apt-get install git tmux daemon ack htop

### Set up remote syslog
per http://help.papertrailapp.com/kb/configuration/configuring-remote-syslog-from-unixlinux-and-bsdos-x

	$ sudo vim /etc/rsyslog.conf

	*.*                                         @logs.papertrailapp.com:20063

	$ sudo service rsyslog restart

### Git setup
	$ git clone http://github.com/jonstokes/irongrid.git
	$ cd irongrid/
	$ git checkout master
	$ sudo bundle install  # don't forget the sudo!

	$ mkdir tmp/
	$ cp config/database.example.yml config/database.yml
	$ git config credential.helper store

## Bitnami development enviroment setup
### Postgresql
For pg install, see here:
http://www.postgresql.org/download/linux/ubuntu/

Create the file /etc/apt/sources.list.d/pgdg.list, and add a line for the repository

deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main

Import the repository signing key, and update the package lists

	$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
	$ sudo apt-get update
	$ sudo apt-get install postgresql-9.3 postgresql-contrib-9.3

(http://www.filippozanella.com/blog/setting-up-postgresql-on-ubuntu-precise12-04-ruby-on-rails-ror3-2-11-ruby1-9-3-and-heroku-gem2-34-0/)

	$ sudo -u postgres psql postgres

Set a password, but leave it blank (hit enter to leave this blank)

	# \password 

Exit out of Postgres commandline

	# \q

Setup the databases

	$ sudo -u postgres createdb irongrid_development
	$ sudo -u postgres createdb irongrid_test

## Elasticsearch

	$ sudo apt-get install openjdk-7-jre-headless -y

per https://gist.github.com/wingdspur/2026107

	$ wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.9.deb
	$ sudo dpkg -i elasticsearch-0.90.9.deb

## Phantomjs
https://coderwall.com/p/rs63ea

	$ cd /usr/local/share
	$ sudo wget sudo wget https://phantomjs.googlecode.com/files/phantomjs-1.9.0-linux-x86_64.tar.bz2
	$ sudo tar xjf phantomjs-1.9.0-linux-x86_64.tar.bz2
	$ sudo ln -s /usr/local/share/phantomjs-1.9.0-linux-x8664/bin/phantomjs /usr/local/share/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.0-linux-x8664/bin/phantomjs /usr/local/bin/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.0-linux-x86_64/bin/phantomjs /usr/bin/phantomjs
	$ phantomjs --version

	$ sudo rm /usr/local/share/phantomjs
	$ sudo rm /usr/local/bin/phantomjs
	$ sudo rm /usr/bin/phantomjs
	$ cd /usr/local/share
	$ sudo wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-x86_64.tar.bz2
	$ sudo tar xjf phantomjs-1.9.7-linux-x86_64.tar.bz2
	$ sudo ln -s /usr/local/share/phantomjs-1.9.7-linux-x8664/bin/phantomjs /usr/local/share/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.7-linux-x8664/bin/phantomjs /usr/local/bin/phantomjs; sudo ln -s /usr/local/share/phantomjs-1.9.7-linux-x86_64/bin/phantomjs /usr/bin/phantomjs
	$ phantomjs --version

## OSX Development Environment Setup
Install Homebrew

	$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Install the stack

	$ \curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby --gems=rails,puma
	$ brew update
	$ brew install postgres
	$ brew install redis
	$ brew install elasticsearch

Install Bundler (if you haven't already):

	$ gem install bundler
