require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "dm-core"

Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Creates clients for checked loan files' loan applications which do not have corresponding client records created"
  task :create_clients_for_loan_files do
    log_folder = File.join(Merb.root, "log", "loan_application_workflow")
    FileUtils.mkdir_p log_folder
    error_filename = File.join(log_folder, "client_creation_log_#{DateTime.now.strftime('%Y-%m-%d_%H:%M')}")
    File.open(error_filename, 'w')
    loan_files = LoanFile.all(:health_check_status => Constants::Status::HEALTH_CHECK_APPROVED)
    loan_files.each do |lf|
      if lf.loan_applications.aggregate(:client_id).include?(nil)
        puts "Creating clients for loan file #{lf.loan_file_identifier}"
        
        return_status = lf.create_clients
        FasterCSV.open(error_filename, "a") do |csv|
          csv << ["Loan File ID:", lf.id, "Loan File Identifier", lf.loan_file_identifier]
          if return_status == false
            csv << ["Something untoward has happened"]
          else
            csv << ["Loan Applications for which clients have been created"]
            csv << ["loan application id", "created client id"]
            return_status[:clients_created].each do |pair|
              csv << pair
            end
            csv << ["Loan Application IDs for which Clients have not been created"]
            csv << ["loan application id", "client creation errors"]
            return_status[:clients_not_created].each do |error_pair|
              csv << error_pair
            end
          end
        end
      end
      if return_status.is_a?(Hash)
        puts "Status => Clients created for Loan IDs    : #{return_status[:clients_created]}"
        puts "Status => Clients not created for Loan IDs: #{return_status[:clients_not_created]}"
      elsif return_status == false
        puts "Status => Loan File is not approved by Health Check. Hence clients will not be created"
      end
    end
  end
end
