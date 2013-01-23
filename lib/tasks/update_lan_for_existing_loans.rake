#this rake task will change the LAN for existing loans back to original Suryoday LAN.
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
    desc "This rake task will update LAN for existing loans back to their original LAN of Suryoday"
    task :update_lan_for_existing_loan, :directory do |t, args|
     require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:update_lan_for_existing_loan[<'directory'>]
USAGE_TEXT

      CLIENT_NAME_COLUMN = 'client'
      UPLOAD_REFERENCE_COLUMN = 'upload_reference'
      CENTER_COLUMN = 'center'
      BRANCH_COLUMN = 'branch'
      LAN_COLUMN = 'lan'
      
      results = {}
      instance_file_prefix = 'update_lan_for_existing_loan' + '_' + DateTime.now.to_s
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
          loan_ids_read = []; loans_not_found = []; loan_ids_updated = []; errors = [];
          FasterCSV.foreach(file_to_read, file_options) do |row|
            client_name = row[CLIENT_NAME_COLUMN]; upload_reference = row[UPLOAD_REFERENCE_COLUMN]; center = row[CENTER_COLUMN]; branch = row[BRANCH_COLUMN];
            lan = row[LAN_COLUMN];
            
            loan = nil
            loan = Lending.first(:loan_borrower_id => upload_reference)
            unless loan
              errors << [upload_reference, "loan not found"]
              loans_not_found << [upload_reference]
              next
            end
            loan_ids_read << [loan.id]
            
            loan.lan = lan
            loan.save!
          end

          unless errors.empty?
            FasterCSV.open(error_file_path, "a") { |fastercsv|
              errors.each do |error|
                fastercsv << error
              end
            }
          end

          FasterCSV.open(success_file_path, "a") { |fastercsv|
            loan_ids_updated.each do |cid|
              fastercsv << cid
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