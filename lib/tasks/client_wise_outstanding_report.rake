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

  desc "Generates Client Wise Outstanding Report using Loan History methods"
  task :new_client_wise_outstanding_report do
    sl_no = 0
    all_loan_ids = Loan.all.aggregate(:id)
    date1 = Date.new(2012, 9, 26)
    date2 = Date.new(2012, 9, 27)
    date3 = Date.new(2012, 10, 01)

    f = File.open("tmp/new_client_wise_outstanding_report_#{DateTime.now.to_s}.csv", "w")
    #f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Gender\", \"Loan Id\", \"Loan Amount\", \"Loan Status\", \"Cycle No.\", \"Interest Rate\", \"Disbursal Date\", \"Scheduled First Payment Date\", \"Actual First Payment Date\", \"Loan Tenure\", \"Installment Frequency\", \"Loan Product\", \"Actual Principal Outstanding as on 26th Sept 2012\", \"Actual Principal Outstanding as on 27th Sept 2012\", \"Actual Principal Outstanding as on 1st Oct 2012\", \"Actual Interest Outstanding as on 26th Sept 2012\", \"Actual Interest Outstanding as on 27th Sept 2012\", \"Interest Outstanding as on 1st Oct 2012\", \"Scheduled Principal Outstanding as on 26th Sept 2012\", \"Scheduled Principal Outstanding as on 27th Sept 2012\", \"Scheduled Principal Outstanding as on 1st Oct 2012\", \"Scheduled Interest Outstanding as on 26th Sept 2012\", \"Scheduled Interest Outstanding as on 27th Sept 2012\", \"Scheduled Outstanding as on 1st Oct 2012\"")

    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Gender\", \"Loan Id\", \"Loan Amount\", \"Loan Status\", \"Cycle No.\", \"Interest Rate\", \"Disbursal Date\", \"Scheduled First Payment Date\", \"Actual First Payment Date\", \"Loan Tenure\", \"Installment Frequency\", \"Loan Product\", \"Actual Principal Outstanding as on 26th Sept 2012\", \"Actual Interest Outstanding as on 26th Sept 2012\", \"Scheduled Principal Outstanding as on 26th Sept 2012\", \"Scheduled Interest Outstanding as on 26th Sept 2012\"")

    loan_ids = LoanHistory.all(:loan_id => all_loan_ids, :status => :outstanding).aggregate(:loan_id)
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

      loan_history_as_on_date1 = loan.loan_history.latest.first
      principal_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_principal
      interest_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_interest
      scheduled_principal_outstanding_as_on_date1 = loan_history_as_on_date1.scheduled_outstanding_principal
      scheduled_interest_outstanding_as_on_date1 = loan_history_as_on_date1.scheduled_outstanding_total - loan_history_as_on_date1.scheduled_outstanding_principal

      # principal_outstanding_as_on_date2 = loan.actual_outstanding_principal_on(date2)
      # principal_outstanding_as_on_date3 = loan.actual_outstanding_principal_on(date3)
      
      # interest_outstanding_as_on_date2 = loan.actual_outstanding_interest_on(date2)
      # interest_outstanding_as_on_date3 = loan.actual_outstanding_interest_on(date3)
      loan_scheduled_first_repayment_date = loan.scheduled_first_payment_date
      loan_actual_first_repayment_date = loan.payments(:type => [:principal, :interest]).min(:received_on)
      
      # scheduled_principal_outstanding_as_on_date2 = loan.scheduled_outstanding_principal_on(date2)
      # scheduled_principal_outstanding_as_on_date3 = loan.scheduled_outstanding_principal_on(date3)
      
      # scheduled_interest_outstanding_as_on_date2 = loan.scheduled_outstanding_interest_on(date2)
      # scheduled_interest_outstanding_as_on_date3 = loan.scheduled_outstanding_interest_on(date3)

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

      # f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_gender}\", #{loan_id}, #{loan_amount}, \"#{loan_status}\", #{loan_cycle_number}, #{loan_interest_rate}, #{loan_disbursal_date}, #{loan_scheduled_first_repayment_date}, #{loan_actual_first_repayment_date}, #{loan_number_of_installments}, \"#{loan_installment_frequency}\", \"#{loan_product}\", #{principal_outstanding_as_on_date1}, #{principal_outstanding_as_on_date2}, #{principal_outstanding_as_on_date3}, #{interest_outstanding_as_on_date1}, #{interest_outstanding_as_on_date2}, #{interest_outstanding_as_on_date3}, #{scheduled_principal_outstanding_as_on_date1}, #{scheduled_principal_outstanding_as_on_date2}, #{scheduled_principal_outstanding_as_on_date3}, #{scheduled_interest_outstanding_as_on_date1}, #{scheduled_interest_outstanding_as_on_date2}, #{scheduled_interest_outstanding_as_on_date3}")
        
      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_gender}\", #{loan_id}, #{loan_amount}, \"#{loan_status}\", #{loan_cycle_number}, #{loan_interest_rate}, #{loan_disbursal_date}, #{loan_scheduled_first_repayment_date}, #{loan_actual_first_repayment_date}, #{loan_number_of_installments}, \"#{loan_installment_frequency}\", \"#{loan_product}\", #{principal_outstanding_as_on_date1}, #{interest_outstanding_as_on_date1}, #{scheduled_principal_outstanding_as_on_date1}, #{scheduled_interest_outstanding_as_on_date1}")
    end
    f.close
  end

  desc "Generates Client Wise Outstanding Report using Loan History methods new"
  task :new_client_wise_outstanding_report_using_loan_history do
    sl_no = 0
    all_loan_ids = Loan.all.aggregate(:id)
    date1 = Date.new(2012, 9, 26)
    date2 = Date.new(2012, 9, 30)

    f = File.open("tmp/new_client_wise_outstanding_report_using_loan_history#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Gender\", \"Loan Id\", \"Loan Amount\", \"Loan Status\", \"Cycle No.\", \"Interest Rate\", \"Disbursal Date\", \"First Payment Date\", \"Loan Tenure\", \"Installment Frequency\", \"Loan Product\", \"Actual Principal Outstanding as on 26th Sept 2012\", \"Actual Interest Outstanding as on 26th Sept 2012\", \"Scheduled Principal Outstanding as on 26th Sept 2012\", \"Scheduled Interest Outstanding as on 26th Sept 2012\", \"Actual Principal Outstanding as on 30th Sept 2012\", \"Actual Interest Outstanding as on 30th Sept 2012\", \"Scheduled Principal Outstanding as on 30th Sept 2012\", \"Scheduled Interest Outstanding as on 30th Sept 2012\", \"Last Payment Date before 30th Sept 2012\"")

    all_loan_ids.each do |l|
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

      loan_history_as_on_date1 = loan.loan_history(:date.lte => date1).last
      principal_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_principal
      interest_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_interest
      scheduled_principal_outstanding_as_on_date1 = loan_history_as_on_date1.scheduled_outstanding_principal
      scheduled_interest_outstanding_as_on_date1 = (loan_history_as_on_date1.scheduled_outstanding_total - loan_history_as_on_date1.scheduled_outstanding_principal)

      loan_history_as_on_date2 = loan.loan_history(:date.lte => date2).last
      principal_outstanding_as_on_date2 = loan_history_as_on_date2.actual_outstanding_principal
      interest_outstanding_as_on_date2 = loan_history_as_on_date2.actual_outstanding_interest
      scheduled_principal_outstanding_as_on_date2 = loan_history_as_on_date2.scheduled_outstanding_principal
      scheduled_interest_outstanding_as_on_date2 = (loan_history_as_on_date2.scheduled_outstanding_total - loan_history_as_on_date2.scheduled_outstanding_principal)

      if loan.payments(:type => [:principal, :interest]).empty?
        loan_first_repayment_date = loan.scheduled_first_payment_date
      else
        loan_first_repayment_date = loan.payments(:type => [:principal, :interest]).min(:received_on)
      end

      if loan.payments(:type => [:principal, :interest]).empty?
        last_payment_date_before_30th_sept_2012 = "No Payments received yet"
      else
        last_payment_date_before_30th_sept_2012 = loan.payments(:received_on.lte => date2, :type => [:principal, :interest]).last.received_on
      end

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

      f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_gender}\", #{loan_id}, #{loan_amount}, \"#{loan_status}\", #{loan_cycle_number}, #{loan_interest_rate}, #{loan_disbursal_date}, #{loan_first_repayment_date}, #{loan_number_of_installments}, \"#{loan_installment_frequency}\", \"#{loan_product}\", #{principal_outstanding_as_on_date1}, #{interest_outstanding_as_on_date1}, #{scheduled_principal_outstanding_as_on_date1}, #{scheduled_interest_outstanding_as_on_date1}, #{principal_outstanding_as_on_date2}, #{interest_outstanding_as_on_date2}, #{scheduled_principal_outstanding_as_on_date2}, #{scheduled_interest_outstanding_as_on_date2}, #{last_payment_date_before_30th_sept_2012}")
    end
    f.close
  end

  desc "Generates Client Wise Outstanding Report as of 31st December 2012"
  task :new_client_wise_outstanding_report_as_of_31st_Dec_2012 do
    sl_no = 0
    all_loan_ids = Loan.all.aggregate(:id)
    date1 = Date.new(2012, 12, 31)

    f = File.open("tmp/new_client_wise_outstanding_report_as_of_31st_dec_2012#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\",\"Branch Id\",\"Branch Name\",\"Center Id\",\"Center Name\",\"Client Id\",\"Client Name\",\"Gender\",\"Loan Id\",\"Loan Amount\",\"Loan Status\",\"Cycle No.\",\"Interest Rate\",\"Disbursal Date\",\"First Payment Date\",\"Loan Tenure\",\"Installment Frequency\",\"Loan Product\",\"Actual Principal Outstanding\",\"Actual Interest Outstanding\",\"Scheduled Principal Outstanding\",\"Scheduled Interest Outstanding\",\"Last Payment Date before 31st Dec 2012\"")

    all_loan_ids.each do |l|
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

      loan_history_as_on_date1 = loan.loan_history(:date.lte => date1).last
      principal_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_principal
      interest_outstanding_as_on_date1 = loan_history_as_on_date1.actual_outstanding_interest
      scheduled_principal_outstanding_as_on_date1 = loan_history_as_on_date1.scheduled_outstanding_principal
      scheduled_interest_outstanding_as_on_date1 = (loan_history_as_on_date1.scheduled_outstanding_total - loan_history_as_on_date1.scheduled_outstanding_principal)

      if loan.payments(:type => [:principal, :interest]).empty?
        loan_first_repayment_date = loan.scheduled_first_payment_date
      else
        loan_first_repayment_date = loan.payments(:type => [:principal, :interest]).min(:received_on)
      end

      loan_payments = loan.payments(:received_on.lte => date1, :type => [:principal, :interest])
      last_payment_date_before_31st_dec_2012 = (loan_payments and not (loan_payments.empty?)) ? loan_payments.last.received_on : "No Payments received yet"
      
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

      f.puts("#{sl_no},#{branch_id},\"#{branch_name}\",#{center_id},\"#{center_name}\",#{client_id},\"#{client_name}\",\"#{client_gender}\",#{loan_id},#{loan_amount},\"#{loan_status}\",#{loan_cycle_number},#{loan_interest_rate},#{loan_disbursal_date},#{loan_first_repayment_date},#{loan_number_of_installments},\"#{loan_installment_frequency}\",\"#{loan_product}\",#{principal_outstanding_as_on_date1},#{interest_outstanding_as_on_date1},#{scheduled_principal_outstanding_as_on_date1},#{scheduled_interest_outstanding_as_on_date1},#{last_payment_date_before_31st_dec_2012}")
    end
    f.close
  end
end
