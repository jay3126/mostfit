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
  desc "Report to find loans which are repaid, closed for Intellecash"
  task :loan_closed_report do
    f = File.open("tmp/closed_loan_report_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl.No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Loan Id\", \"Loan Amount\", \"Disbursement Date\", \"Loan Closing Date\", \"Status of loan\", \"Processing Fees Collected from Client\", \"Actual Outstanding Principal\", \"Actual Outstanding Interest\"")

    all_loan_ids = Loan.all.aggregate(:id)
    loan_ids = LoanHistory.all(:loan_id => all_loan_ids, :status => [:repaid, :preclosed, :claim_settlement]).aggregate(:loan_id)

    sl_no = 0
    date = Date.new(2012, 03, 22)

    loan_ids.each do |l|

      sl_no += 1

      loan = Loan.get(l)
      loan_id = loan.id
      loan_amount = loan.amount
      loan_disbursal_date = loan.disbursal_date
      loan_closing_date = loan.c_last_payment_received_on
      loan_status = loan.status.to_s.capitalize rescue "Something went wrong"
      loan_actual_outstanding_principal = loan.actual_outstanding_principal_on(date) rescue "Something went wrong"
      loan_actual_outstanding_interest = loan.actual_outstanding_interest_on(date) rescue "Something went wrong"

      client = Client.get(loan.client_id)
      client_id = client.id
      client_name = client.name

      center = Center.get(client.center_id)
      center_id = center.id
      center_name = center.name

      branch = Branch.get(center.branch_id)
      branch_id = branch.id
      branch_name = branch.name

      fees = Payment.all(:type => :fees, :fee_id => Fee.first.id, :loan_id => loan.id, :client_id => client.id)
      fees_amount = fees[0].amount rescue "No Fees"

      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", #{loan_id}, #{loan_amount}, #{loan_disbursal_date}, #{loan_closing_date}, \"#{loan_status}\", #{fees_amount}, #{loan_actual_outstanding_principal}, #{loan_actual_outstanding_interest}")
    end
    f.close
  end
end
