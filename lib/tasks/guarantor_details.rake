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

    loan_ids = Loan.all(:disbursal_date.gte => Date.new(2012, 07, 01), :disbursal_date.lte => Date.new(2012, 07, 31)).aggregate(:id)

    sl_no = 0  #this variable is for serial number.

    f = File.open("tmp/guarantor_details_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Client Gender\", \"Client Date Of Birth\", \"Client Age\", \"Client Occupation\", \"Client Group\", \"Spouse Name\", \"Spouse Date Of Birth\", \"Spouse Age\", \"Guarantor Id\", \"Guarantor Name\", \"Guarantor Gender\", \"Guarantor Date Of Birth\", \"Guarantor Age\", \"Relation to Client\", \"Loan Id\", \"Loan Amount\", \"Loan Disbursal Date\", \"Loan Status\"")

    loan_ids.each do |l|

      loan = Loan.get(l)

      sl_no += 1

      loan_id = loan.id
      loan_amount = (loan and loan.amount) ? loan.amount : "Not Specified"
      loan_disbursal_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Specified"
      loan_status = loan.status

      client_id = (loan and loan.client) ? loan.client.id : "Not Specified"
      client_name = (loan and loan.client) ? loan.client.name : "Not Specified"
      client_gender = (loan.client and loan.client.gender) ? loan.client.gender.capitalize : "Not Specified"
      client_date_of_birth = loan.client ? loan.client.date_of_birth : "Not Specified"
      client_age = (loan.client and loan.client.date_of_birth) ? (Date.today.year - loan.client.date_of_birth.year) : "Not Specified"
      client_occupation = (loan.client and loan.client.occupation) ? loan.client.occupation.name : "Not Specified"
      client_group = (loan.client and loan.client.client_group) ? loan.client.client_group.name : "Not Specified"

      spouse_name = (loan and loan.client and loan.client.spouse_name) ? loan.client.spouse_name : "Not Specified"
      spouse_date_of_birth = (loan and loan.client and loan.client.spouse_date_of_birth) ? loan.client.spouse_date_of_birth : "Not Specified"
      spouse_age = (loan and loan.client and loan.client.spouse_date_of_birth) ? (Date.today.year - loan.client.spouse_date_of_birth.year) : "Not Specified"

      guarantor = loan.client.guarantors.first
      guarantor_id = guarantor ? guarantor.id : "Not Specified"
      guarantor_name = guarantor.name if (guarantor and guarantor.name)
      guarantor_gender = (guarantor and guarantor.gender) ? guarantor.gender.capitalize : "Not Specified"
      guarantor_date_of_birth = (guarantor and guarantor.date_of_birth) ? guarantor.date_of_birth : "Not Specified"
      guarantor_age = (guarantor and guarantor.date_of_birth) ? (Date.today.year - guarantor.date_of_birth.year) : "Not Specified"
      guarantor_relation_to_client = (guarantor and guarantor.relationship_to_client) ? guarantor.relationship_to_client : "Not Specified"

      center_id = loan.client.center.id
      center_name = loan.client.center.name

      branch_id = loan.client.center.branch.id
      branch_name = loan.client.center.branch.name

      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_gender}\", #{client_date_of_birth}, #{client_age}, \"#{client_occupation}\", \"#{client_group}\", \"#{spouse_name}\", #{spouse_date_of_birth}, #{spouse_age}, #{guarantor_id}, \"#{guarantor_name}\", \"#{guarantor_gender}\", #{guarantor_date_of_birth}, #{guarantor_age}, \"#{guarantor_relation_to_client}\", #{loan_id}, #{loan_amount}, #{loan_disbursal_date}, \"#{loan_status}\"")
    end
    f.close
  end
end
