# For IronGrid Migration
 * Convert all loadables to new format
 * Move over all ironsights-sites adapters to new loadables manifest
 * Set up production IAM key, bucket, policy, etc. for S3 snapshot backups and test it out.

# Bring up test migration for front end
Delete Test Found cluster
Bring up new Found cluster and set ELASTICSEARCH_URL_REMOTE to it in application.yml

RAILS_ENV=production bundle exec rake index:create_with_alias

Set INDEX_NAME in application.yml to actual index name (not alias) from previous command output

RAILS_ENV=production bundle exec migrate:geo_data
RAILS_ENV=production bundle exec migrate:listings

# For front end
 * Once the migration is done, start work on front end