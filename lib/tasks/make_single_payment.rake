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
    task :make_single_payment, :branch_name, :file_name do |t, args|
      require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:make_single_payment[<'branch_name'>, <'file_name'>]
Convert loans tab in the upload file to a .csv to use as <file_name>
USAGE_TEXT

      LAN_NO_COLUMN = 'LAN No'
      POS_COLUMN = 'POS'
      AS_ON_DATE_COLUMN = 'AS On Date'
      RECEIVED_BY_STAFF_ID = 1; CREATED_BY_USER_ID = 1
      begin
        branch_name_str = args[:branch_name]
        raise ArgumentError, "branch name supplied #{branch_name_str} is invalid" unless (branch_name_str and not (branch_name_str.empty?))
        branch = Branch.first(:name => branch_name_str)
        raise ArgumentError, "No branch found with name #{branch_name_str}" unless branch

        file_name_str = args[:file_name]
        raise ArgumentError, "File name supplied #{file_name_str} is invalid" unless (file_name_str and not (file_name_str.empty?))
        read_file_path = File.join(Merb.root, file_name_str)

        file_options = {:headers => true}
        loan_ids_read = []; loans_not_found = []; loan_ids_updated = []; errors = []
        FasterCSV.foreach(read_file_path, file_options) do |row|
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
          p principal_receipt
          if (principal_receipt > 0)
            branch_id = loan.c_branch_id; center_id = loan.c_center_id
            principal_repayment = Payment.create(:type => :principal, :amount => principal_receipt, :received_on => as_on_date,
              :received_by_staff_id => RECEIVED_BY_STAFF_ID, :created_by_user_id => CREATED_BY_USER_ID, :loan_id => loan.id,
              :c_branch_id => branch_id, :c_center_id => center_id)
            if (principal_repayment and principal_repayment.valid?)
              loan.update_history
              loan_ids_updated << [loan.id]
            else
              p principal_repayment.errors
              errors << [reference, "payment not saved"]
            end
          end
        end

        unless errors.empty?
          error_file_path = read_file_path + '_errors.csv'
          FasterCSV.open(error_file_path, "w") { |fastercsv|
            errors.each do |error|
              fastercsv << error
            end
          }
        end
        
        success_file_path = read_file_path + '_success.csv'
        FasterCSV.open(success_file_path, "w") { |fastercsv|
          loan_ids_updated.each do |lid|
            fastercsv << lid
          end
        }

        p "For branch #{branch_name_str} using file: #{read_file_path}"
        p "loan ids read: #{loan_ids_read.length}"
        p "loan ids updated: #{loan_ids_updated.length}"
        p "loan ids not found: #{loans_not_found.length}"
        p "#{errors.empty? ? "No errors" : "Errors written to #{error_file_path}"}"
        p "Loan ids updated written to #{success_file_path}"

      rescue => ex
        p "An exception occurred: #{ex}"
        p USAGE
      end
    end
  end
end
                             
