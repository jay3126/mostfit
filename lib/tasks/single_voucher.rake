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
    task :single_voucher do
      
      JournalType.all(:name => "journal").destroy!
      [Journal].each do |model|
        table=model.to_s.snake_case.pluralize
        model.all.each do |obj|        
          repository.adapter.execute("update #{table} set journal_type_id='2' where journal_type_id= '3' ")
          
        end        
      end	   
      
      Posting.all.each do |post|  
         table=Posting.to_s.snake_case.pluralize
        Journal.all.each do |jou|
          repository.adapter.execute("update #{table} set journal_type_id = '#{jou.journal_type_id}',date = '#{jou.date}' where journal_id = #{jou.id}")	
         
        end				       
      end	  	   
    end
  end
end

