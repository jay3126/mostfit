require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Updates cycle_number for loans which are second in number for clients"
  task :update_loan_cycle_number do
    l = Loan.all(:amount => [12000, 15000])
    puts "loan ids are:"
    l.aggregate(:id).each{|ids|
      puts ids
    }
    lc = l.aggregate(:id).count
    puts "Total number of loans update are : #{lc}"
    i = 1
    l.each{|loan|
      puts "doing #{i} of #{lc}"
      loan.cycle_number = 2
      loan.save!
      loan.update_history
      i += 1
    }
  end
end
