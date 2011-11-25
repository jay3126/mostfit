require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :conversion do
    desc "convert intellecash db to takeover-intellecash"
    task :reallocate_all_loans do
      t = DateTime.now
      log = File.open('log/reallocated.log','w')
      already_done = File.read('log/reallocated.log').split("\n")
      last_id = already_done[-1].to_i rescue 0
      puts "Last id = #{last_id}. Continuing from #{last_id + 1}. Press any key to continue"
      gets
      lids = Loan.all(:id.gt => last_id).aggregate(:id)
      loan_count = lids.count
      puts "doing #{loan_count} loans"
      lids.each_with_index do |lid,i|
        puts "\ndoing loan id #{lid} (#{i}/#{loan_count}"
        l = Loan.get(lid)
        next if loan.status != :outstanding
        l.reallocate(:normal, l.payments.last.created_by)
        log.write("#{lid}\n")
        elapsed = DateTime.now - t
        print "#{elapsed}.round(2). ETA #{(loan_count - i) * (elapsed/i)/60} mins"
      end
    end
  end
end
