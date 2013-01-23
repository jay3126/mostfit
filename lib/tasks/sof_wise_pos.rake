#this rake task will generate SOF wise POS.
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
    desc "This rake task will generate SOF wise POS"
    task :sof_wise_pos do
      t1 = Time.now
      date = Date.new(2012, 12, 31)
      sl_no = 0

      f = File.open("tmp/sof_wise_pos_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Sl. No.\",\"Branch Name\",\"Center Name\",\"Client Id\",\"Client Name\",\"Funding Line\",\"Loan System Id\",\"LAN\",\"POS\",\"IOS\",\"Total OS\",\"Principal Received Till Date\",\"Interest Received Till Date\",\"Advance Received\",\"Total Received Till Date\"")

      default_currency = MoneyManager.get_default_currency
      funding_line_ids = NewFundingLine.all.aggregate(:id)
      funding_line_ids.each do |fl|
        loan_ids_per_funding_line = FundingLineAddition.all(:funding_line_id => fl).aggregate(:lending_id)
        loan_ids_per_funding_line.each do |l|
          loan = Lending.get(l)
          sl_no += 1
          loan_id = loan.id
          loan_reference_number = loan.lan
          client = loan.borrower
          client_name = client.name
          client_id = client.id
          center_name = BizLocation.get(loan.administered_at_origin).name
          branch_name = BizLocation.get(loan.accounted_at_origin).name
          funding_line = NewFundingLine.get(fl)
          funding_line_name = (funding_line and (not funding_line.nil?)) ? funding_line.name : "Not attached to any Funding Line"

          pos = loan.actual_principal_outstanding(date)
          ios = loan.actual_interest_outstanding(date)
          total_os = pos + ios
          principal_received_till_date = loan.principal_received_till_date
          interest_received_till_date = loan.interest_received_till_date
          advances = LoanReceipt.first(:advance_received.gt => 0, :lending_id => loan.id)
          advance_received = (advances and (not advances.nil?)) ? Money.new(advances.advance_received.to_i, default_currency) : MoneyManager.default_zero_money
          total_received_till_date = principal_received_till_date + interest_received_till_date + advance_received

          f.puts("#{sl_no},\"#{branch_name}\",\"#{center_name}\",#{client_id},\"#{client_name}\",\"#{funding_line_name}\",#{loan_id},\"#{loan_reference_number}\",#{pos},#{ios},#{total_os},#{principal_received_till_date},#{interest_received_till_date},#{advance_received},#{total_received_till_date}")
        end
      end
      f.close
      t2 = Time.now
      puts "Time taken: #{t2-t1} seconds"
      puts "The file is saved in tmp directory with the filename sof_wise_pos"
    end
  end
end