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
  desc "This rake task lists guarantor's details of clients to whom loans were disbursed during Aril 2012 to June 2012"
  task :guarantor_details do

    loan_ids = Loan.all(:disbursal_date.gte => Date.new(2012, 04, 01), :disbursal_date.lte => Date.new(2012, 06, 30)).aggregate(:id)

    sl_no = 0  #this variable is for serial number.

    f = File.open("tmp/guarantor_details_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Guarantor Id\", \"Guarantor Name\", \"Date Of Birth\", \"Relation to Client\", \"Loan Id\", \"Loan Amount\", \"Loan Disbursal Date\", \"Loan Status\"")

    loan_ids.each do |l|

      loan = Loan.get(l)

      sl_no += 1

      loan_id = loan.id
      loan_amount = loan.amount
      loan_disbursal_date = loan.disbursal_date
      loan_status = loan.status

      client_id = loan.client.id
      client_name = loan.client.name

      guarantor = loan.client.guarantors.first
      guarantor_id = guarantor.id
      guarantor_name = guarantor.name
      guarantor_date_of_birth = guarantor.date_of_birth
      guarantor_relation_to_client = guarantor.relation_to_client

      center_id = loan.client.center.id
      center_name = loan.client.center.name

      branch_id = loan.client.center.branch.id
      branch_name = loan.client.center.branch.name

      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", #{guarantor_id}, \"#{guarantor_name}\", #{guarantor_date_of_birth}, \"#{guarantor_relation_to_client}\", #{loan_id}, #{loan_amount}, #{loan_disbursal_date}, \"#{loan_status}\"")
    end
    f.close
  end
end
