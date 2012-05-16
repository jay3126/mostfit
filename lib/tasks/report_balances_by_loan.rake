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
  namespace :reporting do

    desc "report balances by loan at the specified branch on the specified date"
    task :balances_by_loan, :branch_name, :on_date do |t, args|
      require 'fastercsv'
      USE = <<USAGE_TEXT
[bin/]rake mostfit:reporting:balances_by_loan[<'branch_name'>,<'yyyy-mm-dd'>]
Reports the balances on loans at the specified branch on the specified date and writes the same to a file
USAGE_TEXT

      t1                 = Time.now
      output_file_prefix = 'loan_balances'; output_file_suffix = '.csv'
      fq_file_name = nil

      begin
        branch_name = args[:branch_name]
        branch      = Branch.first(:name => branch_name)
        raise ArgumentError, "No branch was found for the name: #{branch_name}" unless branch

        on_date_str = args[:on_date]
        on_date     = Date.parse(on_date_str)

        all_loans_at_branch = branch.loans.aggregate(:id)
        loan_balance_info   = []

        all_loans_at_branch.each { |loan_id|
          loan = Loan.get(loan_id)

          #TODO: Verify these amounts against the daily report
          #TODO: Add totals for the amounts in the spreadsheet
          #TODO: Rounding was not done, and may reveal minute differences

          principal_amount_repaid = Payment.all(:type => :principal, :loan_id => loan_id).aggregate(:amount.sum)
          interest_amount_receipt = Payment.all(:type => :interest, :loan_id => loan_id).aggregate(:amount.sum)

          lh_principal_repaid = LoanHistory.all(:loan_id => loan_id).aggregate(:principal_paid.sum)
          lh_interest_receipt = LoanHistory.all(:loan_id => loan_id).aggregate(:interest_paid.sum)

          pos_calculated = loan.amount - lh_principal_repaid
          ios_calculated = loan.total_interest_to_be_received - lh_interest_receipt

          lan = loan.reference
          loan_balance_info << [loan.id, lan, principal_amount_repaid, lh_principal_repaid, interest_amount_receipt, lh_interest_receipt, pos_calculated, ios_calculated]
        }

        # Remember to change the header row if re-order or change the data being written
        HEADER_ROW = ['System ID', 'LAN', 'Principal repayments', 'LH Principal repayments', 'Interest receipts', 'LH Interest receipts', 'POS', 'IOS']

        sanitised_branch_name = branch_name.gsub(' ', '_')
        output_file_name = output_file_prefix + '.at.' + sanitised_branch_name + '.on.' + on_date.to_s + output_file_suffix
        fq_file_name = File.join(Merb.root, output_file_name)

        header_row_written = false
        FasterCSV.open(fq_file_name, "w") { |fastercsv|
          unless header_row_written
            fastercsv << HEADER_ROW
            header_row_written = true
          end
          loan_balance_info.each do |row|
            fastercsv << row
          end
        }

        t2 = Time.now
        puts "Time Taken: ", (t2-t1)
        puts "The file is saved at the location: ", fq_file_name

      end
    end

  end
end
