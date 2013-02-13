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

    desc "records a fee payment for loans which has been uploaded in the system"
    task :make_fee_payment, :directory do |t, args|
      require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:make_fee_payment[<'directory'>]
Convert lendings tab in the upload file to a .csv and put them into <directory>
USAGE_TEXT

      LAN_NO_COLUMN = 'lan'

      results = {}
      instance_file_prefix = 'single_fee_payment' + '_' + DateTime.now.to_s
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
            lan = row[LAN_NO_COLUMN];

            default_currency = MoneyManager.get_default_currency
            loan = nil
            loan = Lending.first(:lan => lan) if lan
            unless loan
              errors << [lan, "loan not found"]
              loans_not_found << [lan]
              next
            end
            loan_ids_read << [loan.id]
            default_currency = MoneyManager.get_default_currency

            accounting_facade = FacadeFactory.instance.get_instance(FacadeFactory::ACCOUNTING_FACADE, User.first)
            payment_facade = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, User.first)

            if (loan.status == :disbursed_loan_status)
              #making fee payments.
              insurance_policies = loan.simple_insurance_policies.map(&:id) rescue []
              fee_insurances     = FeeInstance.all_unpaid_loan_insurance_fee_instance(insurance_policies) unless insurance_policies.blank?
              fee_instances      = FeeInstance.all_unpaid_loan_fee_instance(loan.id)
              fee_instances      = fee_instances + fee_insurances unless fee_insurances.blank?
              fee_instances.each do |fee_instance|
                fee_payment = payment_facade.record_fee_payment_for_fee_rake_task(fee_instance.id, fee_instance.effective_total_amount, 'receipt', Constants::Transaction::PAYMENT_TOWARDS_FEE_RECEIPT,
                  '','lending', loan.id, 'client', loan.loan_borrower.counterparty_id, loan.administered_at_origin, loan.accounted_at_origin, loan.disbursed_by_staff,
                  loan.disbursal_date, Constants::Transaction::LOAN_FEE_RECEIPT)

                loan_ids_updated << [loan.id, loan.lan, "Payment of #{fee_instance.effective_total_amount} was successfully made"]
              end
            else
              errors << [loan.id, loan.lan, "Payment cannot be made for loans with status : #{loan.status.humanize}"]
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
