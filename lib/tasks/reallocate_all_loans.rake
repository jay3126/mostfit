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
      _now = Time.now
      already_done = File.read('log/reallocated.log').split("\n") rescue []
      log = File.open('log/reallocated.log','w')
      last_id = already_done[-1].to_i rescue 0
      puts "Last id = #{last_id}. Continuing from #{last_id + 1}."
      lids = Loan.all(:id.gt => last_id).aggregate(:id)
      debugger
      loan_count = lids.count
      loans_done = 1
      puts "doing #{loan_count} loans"
      lids.each_with_index do |lid,i|
        if File.exists?("tmp/graceful_exit_rake.txt")
          puts "exiting under grace"
          break 
        end
        puts "\ndoing loan id #{lid} (#{i}/#{loan_count}"
        l = Loan.get(lid)
        if l.status != :outstanding
          log.write("#{lid}\n")
          next
        end
        l.reallocate(:normal, l.payments.last.created_by)
        log.write("#{lid}\n")
        debugger
        elapsed = (Time.now - _now).to_i
        print "#{elapsed} secs. ETA #{(loan_count - i) * (elapsed/(loans_done))/60} mins"
        loans_done += 1
      end
    end
  end
end
