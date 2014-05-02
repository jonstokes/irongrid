# Feed refactor
- merge js-feed-adapter branches for both irongrid and ironsights-sites
  into master, and git push
- Bring down grid && git pull
- Update sites in prod redis from repo
  (use site:update_all rake task!)
- Refresh local ES indexes
- Bring grid back up
- Update dashboard app
