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

    desc "calulates POS ad IOS"
    task :calculating_pos_ios, :directory do |t, args|
      require 'fastercsv'
      USE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:calculating_pos_ios[<'directory'>]
Convert loans tab in the upload file to a .csv and put them into <directory>
USAGE_TEXT

      t1= Time.now
      LAN_NO_COLUMN = 'reference'
      POS_COLUMN = 'POS'
      INTEREST_OUTSTANDING_COLUMN = 'Int OS'
      AS_ON_DATE_COLUMN = 'arguments'
      RECEIVED_BY_STAFF_ID = 1; CREATED_BY_USER_ID = 1
      instance_file_prefix = 'calculated_pos_ios_' + DateTime.now.to_s

      begin
        dir_name_str = args[:directory]
        raise ArgumentError, USE unless (dir_name_str and !(dir_name_str.empty?))

        out_dir_name = (dir_name_str + '_out')
        out_dir = FileUtils.mkdir_p(out_dir_name)
        filename = File.join(Merb.root, out_dir_name, instance_file_prefix+ '.csv')
        csv_files_to_read = Dir.entries(dir_name_str)
        csv_files_to_read.each do |csv_loan_tab|
          next if ['.', '..'].include?(csv_loan_tab)
          file_to_read = File.join(Merb.root, dir_name_str, csv_loan_tab)
          
          loans_hash = {}
          file_options = {:headers => true}
          loan_ids_read = []; loans_not_found = [];  errors = []
          FasterCSV.foreach(file_to_read, file_options) do |row|
            reference = row[LAN_NO_COLUMN]; pos_str = row[POS_COLUMN]; as_on_date_str = row[AS_ON_DATE_COLUMN]; int_os_str = row[INTEREST_OUTSTANDING_COLUMN]

            pos = nil
            begin
              pos = pos_str.to_f
            rescue => ex
              errors << [reference, pos_str, "pos not parsed"]
              next
            end

            int_os = nil
            begin 
              int_os = int_os_str.to_f
            rescue => ex
              errors << [reference, int_os_str, "int os not parsed"]
              next
            end

            as_on_date = nil
            begin
              as_on_date = Date.parse(as_on_date_str)
            rescue => ex
              errors << [reference, as_on_date_str, "as on date not parsed"]
              next
            end

            if (as_on_date.year < 1900)
              p "WARNING!!! WARNING!!! WARNING!!!"
              p "Date from the file is being read in the ancient past, for the year #{as_on_date.year}"
              p "Hit Ctrl-C to ABORT NOW otherwise 2000 years are being added to this date as a correction"
              as_on_date = Date.new(as_on_date.year + 2000, as_on_date.mon, as_on_date.day)
            end

            loan = nil
            loan = Loan.first(:reference => reference) if reference
            loans_hash[loan.id] = {:reference => loan.reference, :amount => loan.amount, :input_file_pos => pos, :input_file_ios => int_os}
            unless loan
              errors << [reference, "loan not found"]
              loans_not_found << [reference]
              next
            end
            loan_ids_read << [loan.id]
          end

          FasterCSV.open(filename, "a"){ |fastercsv|
            fastercsv << [ 'Loan ID', 'Reference', 'Amount', 'Total interest to be received', 'input POS', 'input IOS','Calculated POS', 'Calculated IOS']
            loans_hash.keys.each{|loan_id|
              loan = Loan.get(loan_id)
              # In case no payments have been made for this loan, the payments will be considered as 0
              payment_principal_paid = (Payment.all(:type => :principal, :loan_id => loan.id).aggregate(:amount.sum) || 0).to_f.round(2)
              payment_interest_paid = (Payment.all(:type => :interest, :loan_id => loan.id).aggregate(:amount.sum) || 0).to_f.round(2)
              # if not even a single payment has been made on a loan then the loan history might not be generated for that loan
              # in that case the sum of the principal paid amount will be zero
              lh_principal_sum = (LoanHistory.all(:loan_id => loan.id).aggregate(:principal_paid.sum) || 0).to_f.round(2)
              lh_interest_sum = (LoanHistory.all(:loan_id => loan.id).aggregate(:interest_paid.sum) || 0).to_f.round(2)
              pos_calculated = (loan.amount - lh_principal_sum)
              ios_calculated = (loan.total_interest_to_be_received - lh_interest_sum)
              pos_calculated = "loan history and payments not matching" if payment_principal_paid != lh_principal_sum
              ios_calculated = "loan history and payments not matching" if payment_interest_paid != lh_interest_sum
              
              fastercsv << [loan.id, loan.reference, loan.amount, loan.total_interest_to_be_received, loans_hash[loan_id][:input_file_pos], loans_hash[loan_id][:input_file_ios], pos_calculated, ios_calculated]
            }
          }
        end
      end

      t2 = Time.now
      puts "Time Taken: ", (t2-t1)
      puts "The file is saved at the location ", filename
    end
  end
end
