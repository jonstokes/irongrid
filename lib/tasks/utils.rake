desc "Find any orphans in the LinkData table"
task :find_link_data_orphans => :environment do
  ld_members = LinkData.all
  Site.active.each do |site|
    link_data = ld_members.select do |url|
      !!site.domain[URI(url).host] rescue false
    end
    puts "#{site.domain} - found #{link_data.size} potential orphans"
  end
end
