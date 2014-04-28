# Feed refactor
- AvanlinkWorker should be renamed ProductFeedWorker everywhere,
  including ironsights-sites
- RssWorker should be changed to LinkFeedWorker everywhere, including
  ironsights-sites

- merge js-product-feed to master for irongrid and ironsights-sites
- Bring down grid && git pull
- Update sites in prod redis from repo
  (use site:update_all rake task!)
- Bring grid back up
