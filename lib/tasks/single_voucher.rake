require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :data do
    desc "This rake task helps to bringe database at perticular stage for creating single voucher"
    task :update_database_for_creating_single_voucher do
      
      repository.adapter.execute("update journals set journal_type_id='2' where journal_type_id = '3' ")
     
      repository.adapter.execute("
      update postings p, journals j
     set p.journal_type_id = j.journal_type_id,p.date = j.date
    where p.journal_id = j.id")
    end
  end
end

