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
  desc "This will generate report for outstanding balance on date for Dairy Loans"
  task :outstanding_balance_per_loan_for_dairy_loans do
    branch_ids = [4]
    center_ids = [478]
    date = Date.new(2012, 06, 29)   #date for getting the outstanding of Loan.
    sl_no = 0

    f = File.open("tmp/outstanding_balance_per_loan_for_dairy_loans_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Loan Id\", \"Principal Outstanding\"")

    loan_ids = Loan.all(:c_branch_id => branch_ids, :c_center_id => center_ids).aggregate(:id)
    loan_ids.each do |l|
      sl_no += 1
      loan = Loan.get(l)
      loan_id = loan.id
      loan_outstanding = loan.actual_outstanding_principal_on(date)

      branch = Branch.get(loan.c_branch_id)
      branch_id = branch.id
      branch_name = branch.name

      center = Center.get(loan.c_center_id)
      center_id = center.id
      center_name = center.name

      client = Client.get(loan.client_id)
      client_id = client.id
      client_name = client.name

      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", #{loan_id}, #{loan_outstanding}")
    end
    f.close
  end
end
