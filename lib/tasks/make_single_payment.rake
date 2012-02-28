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

    desc "records a single principal repaid payment for each loan to match the POS data in uploads"
    task :make_single_payment, :directory do |t, args|
      require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:make_single_payment[<'directory'>]
Convert loans tab in the upload file to a .csv and put them into <directory>
USAGE_TEXT

      LAN_NO_COLUMN = 'LAN No'
      POS_COLUMN = 'POS'
      AS_ON_DATE_COLUMN = 'AS On Date'
      RECEIVED_BY_STAFF_ID = 1; CREATED_BY_USER_ID = 1
      results = {}
      instance_file_prefix = 'single_payment' + '_' + DateTime.now.to_s
      results_file_name = File.join(Merb.root, instance_file_prefix + ".results")
      begin

        dir_name_str = args[:directory]
        raise ArgumentError, USAGE unless (dir_name_str and !(dir_name_str.empty?))

        out_dir_name = (dir_name_str + '_out')
        out_dir = FileUtils.mkdir_p(out_dir_name)
        error_file_path = File.join(Merb.root, out_dir_name, instance_file_prefix + '_errors.csv')
        success_file_path = File.join(Merb.root, out_dir_name, instance_file_prefix + '_success.csv')

        csv_files_to_read = Dir.entries(dir_name_str)
        results = {}
        csv_files_to_read.each do |csv_loan_tab|
          next if ['.', '..'].include?(csv_loan_tab)
          file_to_read = File.join(Merb.root, dir_name_str, csv_loan_tab)
          file_result = {}

          file_options = {:headers => true}
          loan_ids_read = []; loans_not_found = []; loan_ids_updated = []; errors = []
          FasterCSV.foreach(file_to_read, file_options) do |row|
            reference = row[LAN_NO_COLUMN]; pos_str = row[POS_COLUMN]; as_on_date_str = row[AS_ON_DATE_COLUMN]

            pos = nil
            begin
              pos = pos_str.to_f
            rescue => ex
              errors << [reference, pos_str, "pos not parsed"]
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
            unless loan
              errors << [reference, "loan not found"]
              loans_not_found << [reference]
              next
            end
            loan_ids_read << [loan.id]

            principal_receipt = loan.amount - pos
            if (principal_receipt > 0)
              branch_id = loan.c_branch_id; center_id = loan.c_center_id
              principal_repayment = Payment.create(:type => :principal, :amount => principal_receipt, :received_on => as_on_date,
                :received_by_staff_id => RECEIVED_BY_STAFF_ID, :created_by_user_id => CREATED_BY_USER_ID, :loan_id => loan.id,
                :c_branch_id => branch_id, :c_center_id => center_id)
              if (principal_repayment and principal_repayment.valid?)
                loan.update_history
                loan_ids_updated << [loan.id, "Payments were recorded to match POS"]
              else
                errors << [loan.id, "Payment not saved"]
              end
            else
              loan_ids_updated << [loan.id, "No payment needed"]
            end
          end

          unless errors.empty?
            FasterCSV.open(error_file_path, "a") { |fastercsv|
              errors.each do |error|
                fastercsv << error
              end
            }
          end

          FasterCSV.open(success_file_path, "a") { |fastercsv|
            loan_ids_updated.each do |lid|
              fastercsv << lid
            end
          }

          file_result[:loan_ids_read] = loan_ids_read
          file_result[:loan_ids_updated] = loan_ids_updated
          file_result[:loans_not_found] = loans_not_found
          file_result[:errors] = errors
          file_result[:error_file_path] = error_file_path
          file_result[:success_file_path] = success_file_path

          results[csv_loan_tab] = file_result
        end

        p results

      rescue => ex
        p "An exception occurred: #{ex}"
        p USAGE
      end
    end
  end
end
