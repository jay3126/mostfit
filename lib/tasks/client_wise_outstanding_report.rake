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
  desc "Generates Client Wise Outstanding Report"
  task :client_wise_outstanding_report do
    sl_no = 0
    loan_ids = Loan.all.aggregate(:id)
    date1 = Date.new(2012, 9, 26)
    date2 = Date.new(2012, 9, 27)
    date3 = Date.new(2012, 10, 01)

    f = File.open("tmp/client_wise_outstanding_report_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Gender\", \"Loan Id\", \"Loan Amount\", \"Loan Status\", \"Cycle No.\", \"Interest Rate\", \"Disbursal Date\", \"Scheduled First Payment Date\", \"Actual First Payment Date\", \"Loan Tenure\", \"Installment Frequency\", \"Loan Product\", \"Actual Principal Outstanding as on 26th Sept 2012\", \"Actual Principal Outstanding as on 27th Sept 2012\", \"Actual Principal Outstanding as on 1st Oct 2012\", \"Actual Interest Outstanding as on 26th Sept 2012\", \"Actual Interest Outstanding as on 27th Sept 2012\", \"Interest Outstanding as on 1st Oct 2012\", \"Scheduled Principal Outstanding as on 26th Sept 2012\", \"Scheduled Principal Outstanding as on 27th Sept 2012\", \"Scheduled Principal Outstanding as on 1st Oct 2012\", \"Scheduled Interest Outstanding as on 26th Sept 2012\", \"Scheduled Interest Outstanding as on 27th Sept 2012\", \"Scheduled Outstanding as on 1st Oct 2012\"")

    loan_ids.each do |l|
      loan = Loan.get(l)
      if (loan.status == :outstanding)
        sl_no += 1
        loan_id = loan.id
        loan_amount = (loan and loan.amount) ? loan.amount : "Not Specified"
        loan_disbursal_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Specified"
        loan_interest_rate = (loan and loan.interest_rate) ? (loan.interest_rate * 100) : "Not Specified"
        loan_status = loan.status
        loan_cycle_number = (loan and loan.cycle_number) ? loan.cycle_number : "Not Specified"
        loan_installment_frequency = (loan and loan.installment_frequency) ? loan.installment_frequency : "Not Specified"
        loan_number_of_installments = (loan and loan.number_of_installments) ? loan.number_of_installments : "Not Specified"
        loan_product = (loan and loan.loan_product) ? loan.loan_product.name : "Not Specified"
        principal_outstanding_as_on_date1 = loan.actual_outstanding_principal_on(date1)
        principal_outstanding_as_on_date2 = loan.actual_outstanding_principal_on(date2)
        principal_outstanding_as_on_date3 = loan.actual_outstanding_principal_on(date3)
        interest_outstanding_as_on_date1 = loan.actual_outstanding_interest_on(date1)
        interest_outstanding_as_on_date2 = loan.actual_outstanding_interest_on(date2)
        interest_outstanding_as_on_date3 = loan.actual_outstanding_interest_on(date3)
        loan_scheduled_first_repayment_date = loan.scheduled_first_payment_date
        loan_actual_first_repayment_date = loan.payments(:type => [:principal, :interest]).min(:received_on)
        scheduled_principal_outstanding_as_on_date1 = loan.scheduled_outstanding_principal_on(date1)
        scheduled_principal_outstanding_as_on_date2 = loan.scheduled_outstanding_principal_on(date2)
        scheduled_principal_outstanding_as_on_date3 = loan.scheduled_outstanding_principal_on(date3)
        scheduled_interest_outstanding_as_on_date1 = loan.scheduled_outstanding_interest_on(date1)
        scheduled_interest_outstanding_as_on_date2 = loan.scheduled_outstanding_interest_on(date2)
        scheduled_interest_outstanding_as_on_date3 = loan.scheduled_outstanding_interest_on(date3)

        client = Client.get(loan.client_id)
        client_id = client.id
        client_name = client.name
        client_gender = (client and client.gender) ? client.gender : "Not Specified"

        center = Center.get(client.center_id)
        center_id = center.id
        center_name = center.name

        branch = Branch.get(center.branch_id)
        branch_id = branch.id
        branch_name = branch.name
      
        f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_gender}\", #{loan_id}, #{loan_amount}, \"#{loan_status}\", #{loan_cycle_number}, #{loan_interest_rate}, #{loan_disbursal_date}, #{loan_scheduled_first_repayment_date}, #{loan_actual_first_repayment_date}, #{loan_number_of_installments}, \"#{loan_installment_frequency}\", \"#{loan_product}\", #{principal_outstanding_as_on_date1}, #{principal_outstanding_as_on_date2}, #{principal_outstanding_as_on_date3}, #{interest_outstanding_as_on_date1}, #{interest_outstanding_as_on_date2}, #{interest_outstanding_as_on_date3}, #{scheduled_principal_outstanding_as_on_date1}, #{scheduled_principal_outstanding_as_on_date2}, #{scheduled_principal_outstanding_as_on_date3}, #{scheduled_interest_outstanding_as_on_date1}, #{scheduled_interest_outstanding_as_on_date2}, #{scheduled_interest_outstanding_as_on_date3}")
      end
    end
    f.close
  end

  desc "Generates Client Wise Outstanding Report for all loans"
  task :client_wise_outstanding_report_for_all_loans do
    sl_no = 0
    loan_ids = Loan.all.aggregate(:id)
    date1 = Date.new(2012, 9, 26)
    date2 = Date.new(2012, 9, 27)
    date3 = Date.new(2012, 10, 01)

    f = File.open("tmp/client_wise_outstanding_report_for_all_loans_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Gender\", \"Loan Id\", \"Loan Amount\", \"Loan Status\", \"Cycle No.\", \"Interest Rate\", \"Disbursal Date\", \"Scheduled First Payment Date\", \"Actual First Payment Date\", \"Loan Tenure\", \"Installment Frequency\", \"Loan Product\", \"Actual Principal Outstanding as on 26th Sept 2012\", \"Actual Principal Outstanding as on 27th Sept 2012\", \"Actual Principal Outstanding as on 1st Oct 2012\", \"Actual Interest Outstanding as on 26th Sept 2012\", \"Actual Interest Outstanding as on 27th Sept 2012\", \"Interest Outstanding as on 1st Oct 2012\", \"Scheduled Principal Outstanding as on 26th Sept 2012\", \"Scheduled Principal Outstanding as on 27th Sept 2012\", \"Scheduled Principal Outstanding as on 1st Oct 2012\", \"Scheduled Interest Outstanding as on 26th Sept 2012\", \"Scheduled Interest Outstanding as on 27th Sept 2012\", \"Scheduled Outstanding as on 1st Oct 2012\"")

    loan_ids.each do |l|
      loan = Loan.get(l)
      sl_no += 1
      loan_id = loan.id
      loan_amount = (loan and loan.amount) ? loan.amount : "Not Specified"
      loan_disbursal_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Specified"
      loan_interest_rate = (loan and loan.interest_rate) ? (loan.interest_rate * 100) : "Not Specified"
      loan_status = loan.status
      loan_cycle_number = (loan and loan.cycle_number) ? loan.cycle_number : "Not Specified"
      loan_installment_frequency = (loan and loan.installment_frequency) ? loan.installment_frequency : "Not Specified"
      loan_number_of_installments = (loan and loan.number_of_installments) ? loan.number_of_installments : "Not Specified"
      loan_product = (loan and loan.loan_product) ? loan.loan_product.name : "Not Specified"
      principal_outstanding_as_on_date1 = loan.actual_outstanding_principal_on(date1)
      principal_outstanding_as_on_date2 = loan.actual_outstanding_principal_on(date2)
      principal_outstanding_as_on_date3 = loan.actual_outstanding_principal_on(date3)
      interest_outstanding_as_on_date1 = loan.actual_outstanding_interest_on(date1)
      interest_outstanding_as_on_date2 = loan.actual_outstanding_interest_on(date2)
      interest_outstanding_as_on_date3 = loan.actual_outstanding_interest_on(date3)
      loan_scheduled_first_repayment_date = loan.scheduled_first_payment_date
      loan_actual_first_repayment_date = loan.payments(:type => [:principal, :interest]).min(:received_on)
      scheduled_principal_outstanding_as_on_date1 = loan.scheduled_outstanding_principal_on(date1)
      scheduled_principal_outstanding_as_on_date2 = loan.scheduled_outstanding_principal_on(date2)
      scheduled_principal_outstanding_as_on_date3 = loan.scheduled_outstanding_principal_on(date3)
      scheduled_interest_outstanding_as_on_date1 = loan.scheduled_outstanding_interest_on(date1)
      scheduled_interest_outstanding_as_on_date2 = loan.scheduled_outstanding_interest_on(date2)
      scheduled_interest_outstanding_as_on_date3 = loan.scheduled_outstanding_interest_on(date3)

      client = Client.get(loan.client_id)
      client_id = client.id
      client_name = client.name
      client_gender = (client and client.gender) ? client.gender : "Not Specified"

      center = Center.get(client.center_id)
      center_id = center.id
      center_name = center.name

      branch = Branch.get(center.branch_id)
      branch_id = branch.id
      branch_name = branch.name

      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_gender}\", #{loan_id}, #{loan_amount}, \"#{loan_status}\", #{loan_cycle_number}, #{loan_interest_rate}, #{loan_disbursal_date}, #{loan_scheduled_first_repayment_date}, #{loan_actual_first_repayment_date}, #{loan_number_of_installments}, \"#{loan_installment_frequency}\", \"#{loan_product}\", #{principal_outstanding_as_on_date1}, #{principal_outstanding_as_on_date2}, #{principal_outstanding_as_on_date3}, #{interest_outstanding_as_on_date1}, #{interest_outstanding_as_on_date2}, #{interest_outstanding_as_on_date3}, #{scheduled_principal_outstanding_as_on_date1}, #{scheduled_principal_outstanding_as_on_date2}, #{scheduled_principal_outstanding_as_on_date3}, #{scheduled_interest_outstanding_as_on_date1}, #{scheduled_interest_outstanding_as_on_date2}, #{scheduled_interest_outstanding_as_on_date3}")
    end
    f.close
  end
end
