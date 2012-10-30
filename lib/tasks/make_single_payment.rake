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

    desc "records a single payment for each loan to match the POS data in uploads"
    task :make_single_payment, :directory do |t, args|
      require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:make_single_payment[<'directory'>]
Convert lendings tab in the upload file to a .csv and put them into <directory>
USAGE_TEXT

      LAN_NO_COLUMN = 'lan'
      POS_COLUMN = 'principal_outstanding'
      INTEREST_OUTSTANDING_COLUMN = 'interest_outstanding'
      TOTAL_OUTSTANDING = 'total_outstanding'
      AS_ON_DATE_COLUMN = 'as_on_date'

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
            lan = row[LAN_NO_COLUMN]; pos_str = row[POS_COLUMN]; as_on_date_str = row[AS_ON_DATE_COLUMN]; int_os_str = row[INTEREST_OUTSTANDING_COLUMN]; total_os_str = row[TOTAL_OUTSTANDING];

            default_currency = MoneyManager.get_default_currency
            pos = nil
            begin
              pos = MoneyManager.get_money_instance(pos_str.to_i)
            rescue => ex
              errors << [lan, pos_str, "pos not parsed"]
              next
            end

            int_os = nil
            begin 
              int_os = MoneyManager.get_money_instance(int_os_str.to_i)
            rescue => ex
              errors << [lan, int_os_str, "int os not parsed"]
              next
            end
            
            total_os = nil
            begin 
              total_os = MoneyManager.get_money_instance(total_os_str.to_i)
            rescue => ex
              errors << [lan, total_os_str, "total os not parsed"]
              next
            end

            as_on_date = nil
            begin
              as_on_date = Date.parse(as_on_date_str)
            rescue => ex
              errors << [lan, as_on_date_str, "as on date not parsed"]
              next
            end

            if (as_on_date.year < 1900)
              p "WARNING!!! WARNING!!! WARNING!!!"
              p "Date from the file is being read in the ancient past, for the year #{as_on_date.year}"
              p "Hit Ctrl-C to ABORT NOW otherwise 2000 years are being added to this date as a correction"
              as_on_date = Date.new(as_on_date.year + 2000, as_on_date.mon, as_on_date.day)
            end

            loan = nil
            loan = Lending.first(:lan => lan) if lan
            unless loan
              errors << [lan, "loan not found"]
              loans_not_found << [lan]
              next
            end
            loan_ids_read << [loan.id]
            
            branch_id = loan.accounted_at_origin
            center_id = loan.administered_at_origin
            center = BizLocation.get(center_id)
            performed_by_staff = User.first.staff_member
            recorded_by_staff = User.first
            client = loan.borrower
            principal_amount_from_loan_product = Money.new(loan.lending_product.loan_schedule_template.total_principal_amount.to_i, default_currency)
            interest_amount_from_loan_product = Money.new(loan.lending_product.loan_schedule_template.total_interest_amount.to_i, default_currency)
            amount_to_be_paid = (principal_amount_from_loan_product - pos) + (interest_amount_from_loan_product - int_os)
            money_amount_to_be_paid = amount_to_be_paid

            receipt_type = Constants::Transaction::RECEIPT
            effective_on = as_on_date
            payment_towards = Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT
            product_action   = Constants::Transaction::LOAN_REPAYMENT
            on_product_type = 'lending'
            on_product_id = loan.id
            by_counterparty_type = 'client'
            by_counterparty_id = client.id
            performed_at = center_id
            accounted_at = branch_id
            performed_by = performed_by_staff.id
            recorded_by = recorded_by.id
            receipt_no = loan.id

            #making the payments.
            valid = loan.is_payment_transaction_permitted?(money_amount_to_be_paid, effective_on, performed_by, recorded_by)
            if valid == true
              payment_facade = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, User.first)
              payments = payment_facade.record_payment(money_amount_to_be_paid, receipt_type, payment_towards, receipt_no, on_product_type,
                                                       on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at,
                                                       performed_by, effective_on, product_action)
              loan_ids_updated << [loan.id, loan.lan, client.id, "Payment successfully made"]
            else
              errors << [loan.id, loan.lan, "Payment cannot be saved because: #{valid.last}"]
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
