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
  desc "List of active clients and their active loans as on 31st March 2012 for Intellecash"
  task :active_clients_report do

    f = File.open("tmp/active_loans_report_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Client Group Name\", \"Reference\",\"Type of Reference\", \"Gender\", \"Date of Birth\", \"Date Joined\", \"Religion\", \"Caste\", \"Spouse Name\", \"Spouse Date of Birth\", \"Father's Name\", \"Is Father Alive?\", \"Address\", \"Pin Code\", \"Village\", \"Phone Number\", \"Occupation\", \"Loan Id\", \"Loan Amount\", \"Interest Rate\", \"Installment Frequency\", \"Number of Installments\", \"Number of Installments paid till 31st March 2012\", \"Disbursal Date\", \"Loan Start Date\", \"Last repayment date (on or before 31st march 2012)\", \"Cycle Number\", \"Loan Product Name\", \"Purpose of Loan\", \"EMI\", \"Scheduled Outstanding Principal\", \"Scheduled Outstanding Interest\", \"Scheduled Outstanding Total\", \"Actual Outstanding Principal\", \"Actual Outstanding Interest\", \"Actual Outstanding Total\"")

    sl_no = 0
    date = Date.new(2012, 03, 31)

    active_client_ids = Client.all(:active => true).aggregate(:id)
    active_client_loan_ids = Loan.all(:client_id => active_client_ids).aggregate(:id)

    active_client_loan_ids.each do |l|
      loan = Loan.get(l)
      next unless loan.status == :outstanding

      sl_no += 1

      loan_id = loan.id
      loan_amount = loan.amount
      loan_interest_rate = (loan.interest_rate * 100)
      loan_installment_frequency = loan.installment_frequency.to_s.capitalize
      loan_number_of_installments = loan.number_of_installments
      loan_disbursal_date = loan.disbursal_date
      loan_cycle_number = loan.cycle_number
      loan_product_name = loan.loan_product.name
      loan_purpose = (loan.occupation ? loan.occupation.name : "Not Specified")
      loan_scheduled_outstanding_principal = loan.scheduled_outstanding_principal_on(date)
      loan_scheduled_outstanding_interest = loan.scheduled_outstanding_interest_on(date)
      loan_actual_outstanding_principal = loan.actual_outstanding_principal_on(date)
      loan_actual_outstanding_interest = loan.actual_outstanding_interest_on(date)
      loan_scheduled_outstanding_total = (loan_scheduled_outstanding_principal + loan_scheduled_outstanding_interest)
      loan_actual_outstanding_total = (loan_actual_outstanding_principal + loan_actual_outstanding_interest)
      loan_emi = (loan.scheduled_principal_for_installment(1) + loan.scheduled_interest_for_installment(1))
      loan_start_date = loan.scheduled_first_payment_date
      loan_installments_paid = loan.number_of_installments_before(date)
      loan_last_repayment_date = loan.loan_history.latest.first.date

      client = Client.get(loan.client_id)
      client_id = client.id
      client_name = client.name
      client_group_name = (client.client_group ? client.client_group.name : "Not Attached to any group")
      client_gender = client.gender.capitalize
      client_reference = client.reference
      client_type_of_reference = client.type_of_id.to_s
      client_date_of_birth = client.date_of_birth
      client_date_joined = client.date_joined
      client_religion = client.religion
      client_caste = client.caste
      if client.spouse_name
        client_spouse_name = client.spouse_name
        client_spouse_date_of_birth = client.spouse_date_of_birth
      else
        client_spouse_name = "Not Specified"
        client_spouse_date_of_birth = "Not Specified"
      end
      if client.fathers_name
        client_fathers_name = client.fathers_name
        client_father_alive = client.father_is_alive
      else
        client_fathers_name = "Not Specified"
        client_father_alive = "Not Specified"
      end
      #client_address = client.address
      client_address = "address"
      client_village = (client.village ? client.village.name : "Not Specified")
      client_pin_code = (client.address_pin ? client.address_pin : "Not Specified")
      client_phone_number = (client.phone_number ? client.phone_number : "Not Specified")
      client_occupation = (client.occupation ? client.occupation.name : "Not Specified")
      center_id = client.center.id
      center_name = client.center.name
      branch_id = client.center.branch.id
      branch_name = client.center.branch.name
      
      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_group_name}\", \"#{client_reference}\", \"#{client_type_of_reference}\", \"#{client_gender}\", #{client_date_of_birth}, #{client_date_joined}, \"#{client_religion}\", \"#{client_caste}\", \"#{client_spouse_name}\", #{client_spouse_date_of_birth}, \"#{client_fathers_name}\", \"#{client_father_alive}\", \"#{client_address}\", #{client_pin_code}, \"#{client_village}\", #{client_phone_number}, \"#{client_occupation}\", #{loan_id}, #{loan_amount}, #{loan_interest_rate}, \"#{loan_installment_frequency}\", #{loan_number_of_installments}, #{loan_installments_paid}, #{loan_disbursal_date}, #{loan_start_date}, #{loan_last_repayment_date}, #{loan_cycle_number}, \"#{loan_product_name}\", \"#{loan_purpose}\", #{loan_emi}, #{loan_scheduled_outstanding_principal}, #{loan_scheduled_outstanding_interest}, #{loan_scheduled_outstanding_total}, #{loan_actual_outstanding_principal}, #{loan_actual_outstanding_interest}, #{loan_actual_outstanding_total}")
    end
    f.close
  end
end
