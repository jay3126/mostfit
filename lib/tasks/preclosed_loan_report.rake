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
  desc "This will generate Preclosed loans report"
  task :preclosed_loan_report do
    sl_no = 0   #this variable is for serial number.

    #Dates for determining the range for which report is required.
    date1 = Date.new(2012, 04, 01)
    date2 = Date.new(2012, 9, 26)

    f = File.open("tmp/preclosed_loan_report_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Spouse Name\", \"Loan Id\", \"Loan Amount\", \"Interest Rate\", \"Tenure\", \"Disbursal Date\", \"Preclosure Date\"")

    loan_query_params = {:preclosed_on.gte => date1, :preclosed_on.lte => date2, "loan_history.status" => :preclosed}
    preclosed_loans = Loan.all(loan_query_params).uniq

    preclosed_loans.each do |loan|

      sl_no += 1
      branch = Branch.get(loan.c_branch_id)
      branch_id = branch.id
      branch_name = branch.name
      center = Center.get(loan.c_center_id)
      center_id = center.id
      center_name = center.name
      client = Client.get(loan.client_id)
      client_id = client.id
      client_name = client.name
      spouse_name = client.spouse_name
      loan_id = loan.id
      loan_amount = loan.amount
      interest_rate = loan.interest_rate * 100
      loan_tenure = loan.installment_frequency.to_s
      loan_disbursal_date = loan.disbursal_date
      loan_preclosure_date = loan.preclosed_on

      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{spouse_name}\", #{loan_id}, #{loan_amount}, #{interest_rate}, #{loan_tenure}, #{loan_disbursal_date}, #{loan_preclosure_date}")
    end
    f.close
  end
end
