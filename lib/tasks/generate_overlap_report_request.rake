require "rubygems"

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
  namespace :highmark do
    
    desc "This rake task creates the a Overlap Report Request in the CSV format for Highmark"
    task :overlap_report_request do
      errors = {}
      errors[:generation_errors] = {}
      errors[:save_status_errors] = {}
      loan_applications = LoanApplication.all(:status => :new)
      credit_bureau_name = "Highmark"
      request_name = "overlap_report_request"

      folder = File.join(Merb.root, "docs","highmark","requests")
      FileUtils.mkdir_p folder
      filename = File.join(folder, "#{credit_bureau_name}.#{request_name}.#{DateTime.now.strftime('%Y-%m-%d_%H:%M')}.csv")
      FasterCSV.open(filename, "w", {:col_sep => "|"}) do |csv|
        loan_applications.each do |loan_application|
          begin
            csv << loan_application.row_to_delimited_file
          rescue Exception => error
            errors[:generation_errors][loan_application.id] = error  
          end
          loan_application.status = :pending_overlap_report
          loan_application.save
          errors[:save_status_errors][loan_application.id] = loan_application.errors unless loan_application.save
        end        
      end
      
      log_folder = File.join(Merb.root, "log","highmark","requests")
      FileUtils.mkdir_p folder
      error_filename = File.join(log_folder, "#{credit_bureau_name}.#{request_name}.#{DateTime.now.strftime('%Y-%m-%d_%H:%M')}.csv")
      FasterCSV.open(error_filename, "w", {:col_sep => "|"}) do |csv|
        csv << ["generation_errors"]
        errors[:generation_errors].keys.each do |e|
          csv << errors[:generation_errors][e]
        end
        csv << ["generation_errors"]
        errors[:save_status_errors].keys.each do |e|
          csv << errors[:save_status_errors][e]
        end
      end

    end

  end
end
