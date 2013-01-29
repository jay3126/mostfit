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
  desc "Generates Client Wise Overdue Report as of 31st January 2013"
  task :client_wise_overdue_report do
    sl_no = 0
    all_loan_ids = Loan.all.aggregate(:id)
    date1 = Date.new(2013, 01, 31)

    f = File.open("tmp/client_wise_overdue_report_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Sl. No.\",\"Branch Id\",\"Branch Name\",\"Center Id\",\"Center Name\",\"Client Id\",\"Client Name\",\"Gender\",\"Loan Id\",\"Loan Amount\",\"Loan Status\",\"Cycle No.\",\"Interest Rate\",\"Disbursal Date\",\"First Payment Date\",\"Loan Tenure\",\"Installment Frequency\",\"Loan Product\",\"Last Payment Date till 31st Jan 2013\",\"Principal Overdue\",\"Interest Overdue\",\"Total Overdue\",\"Overdue By No. Of Days\"")

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
      principal_overdue_as_on_date1 = (loan_history_as_on_date1.actual_outstanding_principal > loan_history_as_on_date1.total_principal_paid) ? (loan_history_as_on_date1.actual_outstanding_principal - loan_history_as_on_date1.total_principal_paid) : 0
      interest_overdue_as_on_date1 = (loan_history_as_on_date1.actual_outstanding_interest > loan_history_as_on_date1.total_interest_paid) ? (loan_history_as_on_date1.actual_outstanding_interest - loan_history_as_on_date1.total_interest_paid) : 0
      total_paid_as_on_date1 = loan_history_as_on_date1.total_principal_paid + loan_history_as_on_date1.total_interest_paid
      total_overdue_as_on_date1 = (loan_history_as_on_date1.actual_outstanding_total > total_paid_as_on_date1) ? (loan_history_as_on_date1.actual_outstanding_total - total_paid_as_on_date1) : 0

      if loan.payments(:type => [:principal, :interest]).empty?
        loan_first_repayment_date = loan.scheduled_first_payment_date
      else
        loan_first_repayment_date = loan.payments(:type => [:principal, :interest]).min(:received_on)
      end

      loan_payments = loan.payments(:received_on.lte => date1, :type => [:principal, :interest])
      last_payment_date_before_31st_jan_2013 = (loan_payments and not (loan_payments.empty?)) ? loan_payments.last.received_on : "No Payments received yet"
      number_of_days_in_overdue = (loan_payments and (loan.status == :outstanding) and not (loan_payments.empty?)) ? (Date.today - loan_payments.last.received_on) : 0
      
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

      f.puts("#{sl_no},#{branch_id},\"#{branch_name}\",#{center_id},\"#{center_name}\",#{client_id},\"#{client_name}\",\"#{client_gender}\",#{loan_id},#{loan_amount},\"#{loan_status}\",#{loan_cycle_number},#{loan_interest_rate},#{loan_disbursal_date},#{loan_first_repayment_date},#{loan_number_of_installments},\"#{loan_installment_frequency}\",\"#{loan_product}\",#{last_payment_date_before_31st_jan_2013},#{principal_overdue_as_on_date1},#{interest_overdue_as_on_date1},#{total_overdue_as_on_date1},#{number_of_days_in_overdue}")
    end
    f.close
  end
end
