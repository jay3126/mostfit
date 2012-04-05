require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "dm-core"

Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
    desc "Creates clients for checked loan files' loan applications which do not have corresponding client records created"
    task :create_clients_for_loan_files do
      loan_files = LoanFile.all()
      #take all loan files
      loan_files.each do | lf |
         puts "Creating clients for loan file #{lf.loan_file_identifier}"
         return_status = lf.create_clients
         puts "Status => Clients created for Loan IDs    : #{return_status[:clients_created]}"
         puts "Status => Clients not created for Loan IDs: #{return_status[:clients_not_created]}"
      end
    end
end
