require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "This rake task updates history for all the loans"
  task :update_history do
    t1 = Time.now
    puts "Loan history updation process started at #{t1}"
    l_count = Loan.count
    puts "Total loans count: #{l_count}."
    idx = 0
    loan_ids = Loan.all.aggregate(:id)
    loan_ids.each{|ids|
      idx += 1
      loan = Loan.get(ids)
      puts "doing: #{idx} of #{l_count}.."
      loan.update_history
    }
    t2 = Time.now
    puts "History updation took: #{t2-t1} seconds"
  end
end
