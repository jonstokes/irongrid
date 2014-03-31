# FIRST BOOT
1. Prepare AWS image
2. RAILS_ENV="production" rake db:migrate
3. Commit schema changes from above
4. Copy over application.yml to ec2 repos
5. Copy all sites from local to prod redis
6. Boot services
7. Boot queues from crawls and fast_db
