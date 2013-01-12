#rake task to find out advance received per loan.
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
  namespace :suryoday do
    desc "This rake task will give advance received per loan for migrated loans"
    task :advance_received_per_loan do
      t1 = Time.now
      loan_ids = LoanReceipt.all(:advance_received.gt => 0).aggregate(:lending_id)
      date1 = Date.new(2012, 12, 31)
      sl_no = 0

      f = File.open("tmp/advance_received_per_loan_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Sl. No.\",\"Branch Name\",\"Center Name\",\"Client Id\",\"Client Name\",\"Loan System Id\",\"Loan Reference Number\",\"POS\",\"IOS\",\"Total OS\",\"Principal Received Till Date\",\"Interest Received Till Date\",\"Total Received Till Date\",\"Advance Received\"")

      loan_ids.each do |l|
        loan = Lending.get(l)

        sl_no += 1

        loan_id = loan.id
        loan_reference_number = loan.lan
        client = loan.borrower
        client_name = client.name
        client_id = client.id
        center_name = BizLocation.get(loan.administered_at_origin).name
        branch_name = BizLocation.get(loan.accounted_at_origin).name

        pos = loan.actual_principal_outstanding(date1)
        ios = loan.actual_interest_outstanding(date1)
        total_os = pos + ios
        principal_received_till_date = loan.principal_received_till_date
        interest_received_till_date = loan.interest_received_till_date
        total_received_till_date = principal_received_till_date + interest_received_till_date
        advances = LoanReceipt.first(:advance_received.gt => 0, :lending_id => loan.id)
        advance_received = (advances and (not advances.nil?)) ? Money.new(advances.advance_received.to_i, :INR).to_s : MoneyManager.default_zero_money

        f.puts("#{sl_no},\"#{branch_name}\",\"#{center_name}\",#{client_id},\"#{client_name}\",#{loan_id},\"#{loan_reference_number}\",#{pos},#{ios},#{total_os},#{principal_received_till_date},#{interest_received_till_date},#{total_received_till_date},#{advance_received}")
      end
      f.close
      t2 = Time.now
      puts "Time taken: #{t2-t1} seconds"
      puts "The file is saved in tmp directory with the filename advance_received_per_loan"
    end
  end
end
