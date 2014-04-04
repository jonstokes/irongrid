# FIRST BOOT
- Prepare AWS image
- Copy over application.yml  and database.yml from scoperrific repos to
   irongrid repos
- RAILS_ENV="production" rake db:migrate for irongrid
- Commit schema changes from above
- Copy all sites from local to prod redis
- Boot queues from crawls and fast_db
- Boot delete_ended_auctions_service and test that for a while. Pay
  attention to the LogRecords that are being created
- Boot ReadSitesService and CreateCdnService
