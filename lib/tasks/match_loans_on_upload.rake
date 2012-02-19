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
  namespace :migration do
    desc "given a list of loans and principal outstanding, calculates the expected and current pos and corrections needed to payments"
    task :match_loans_on_upload, :directory do |t, args|
      require 'fastercsv'

      USAGE = <<USAGE_TEXT
      [bin/]rake mostfit:migration:display_receipts_for_loans[<'directory'>]
      Convert loans tab in the upload file to .csv
USAGE_TEXT

      LAN_NO_COLUMN = 'LAN No'
      POS_COLUMN = 'POS'

      TOLERABLE_DIFFERENCE = 0.01
      ROUND_TO_DECIMAL_PLACES = 2
      MAX_LOAN_POS_TO_READ = 20000

      begin
        dir_name_str = args[:directory]
        raise ArgumentError, USAGE unless (dir_name_str and !(dir_name_str.empty?))
        
        out_dir_name = (dir_name_str + '_out')
        out_dir = Dir.mkdir(out_dir_name) unless File.directory?(out_dir_name)
        csv_files_to_read = Dir.entries(dir_name_str)
        results = {}
        csv_files_to_read.each do |csv_loan_tab|
          next if (['.', '..'].include?(csv_loan_tab))
          file_path = File.join(Merb.root, dir_name_str, csv_loan_tab)
          out_file_path = File.join(Merb.root, out_dir_name, csv_loan_tab + '_payment_corrections.csv')
          errors_out_file_path = File.join(Merb.root, out_dir_name, csv_loan_tab + '_errors.csv')
          file_options = { :headers => true }

          loan_and_pos = {}
          errors = []
          results_row = {}
          results_row[:file_path] = file_path
          FasterCSV.foreach(file_path, file_options) do |row|
            loan_reference = row[LAN_NO_COLUMN]
            pos_str = row[POS_COLUMN]
            pos = nil
            begin
              pos = pos_str.to_f
            rescue => ex
              errors << row
            end
            if pos
              if pos > MAX_LOAN_POS_TO_READ
                errors << row
              else
                loan_and_pos[loan_reference] = pos if pos
              end
            end
          end
          number_of_loans_read = loan_and_pos.keys.size
          results_row[:number_of_loans_read] = number_of_loans_read

          loan_and_payments = {}
          total_pos_difference = 0; zero_payments_difference = 0; some_payments_difference = 0;
          loans_payments_error_count = 0; loans_not_found_count = 0; matched_loan_count = 0; mismatched_loan_count = 0
          header_row = ['Loan ID', 'Expected POS', 'Current POS', 'Payment to change', 'Interest receipts']
          loan_and_pos.each { |loan_reference, expected_pos|
            loan = Loan.first(:reference => loan_reference)
            
            unless loan 
              loans_not_found_count += 1
              errors << "Loan with reference #{loan_reference} not found"
              next
            end

            loan_amount = loan.amount
            total_principal_receipts = Payment.all(:loan => loan, :type => :principal).aggregate(:amount.sum)
            interest_receipts = Payment.all(:loan => loan, :type => :interest).aggregate(:amount.sum)

            unless (expected_pos and loan_amount and total_principal_receipts and interest_receipts)
              loan_info = [loan.id, expected_pos, loan_amount, (total_principal_receipts || 0) , (interest_receipts || 0)]
              errors << loan_info
              loans_payments_error_count += 1
              zero_payments_difference += loan_amount
            else
              current_pos = loan_amount - total_principal_receipts
              pos_difference = expected_pos - current_pos
              pos_difference_normal = 0
              if (pos_difference.abs > TOLERABLE_DIFFERENCE)
                pos_difference_normal =  pos_difference.round(ROUND_TO_DECIMAL_PLACES) 
                some_payments_difference += pos_difference_normal
                mismatched_loan_count += 1
              end
              matched_loan_count += 1 if pos_difference_normal == 0

              current_pos = current_pos.round(ROUND_TO_DECIMAL_PLACES)
              interest_receipts = interest_receipts.round(ROUND_TO_DECIMAL_PLACES)
              loan_and_payments[loan.id] = [loan.id, expected_pos, current_pos, pos_difference_normal, interest_receipts]
            end
          }
          total_pos_difference = some_payments_difference + zero_payments_difference
          results_row[:loans_not_found_count] = loans_not_found_count
          results_row[:loans_payments_error_count] = loans_payments_error_count
          results_row[:total_pos_difference] = total_pos_difference
          results_row[:zero_payments_difference] = zero_payments_difference
          results_row[:some_payments_difference] = some_payments_difference
          results_row[:mismatched_loan_count] = mismatched_loan_count
          results_row[:matched_loan_count] = matched_loan_count

          FasterCSV.open(out_file_path, "w") do |csv|
            header_row_written = false
            loan_and_payments.each do |loan_id, data_ary|
              if header_row_written
                csv << data_ary
              else
                csv << header_row
                header_row_written = true
              end
            end
          end
    
          FasterCSV.open(errors_out_file_path, "w") do |errors_csv|
            errors.each do |error|
              errors_csv << error
            end
          end
          number_of_errors = errors.size

          results_row[:number_of_errors] = number_of_errors
          results_row[:errors_out_file_path] = errors_out_file_path
          results_row[:out_file_path] = out_file_path
          results[file_path] = results_row
        end
        ap results
      rescue => ex
        puts "An error occurred: #{ex.backtrace}"
      end
    end
  end
end
