#this rake task will update fields like Caste, Religion, PSL, Sub-PSL, Occupation and Loan Purpose for clients and loans.
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
    desc "This rake task will update existing clients with data for Caste, Religion, PSL, etc.."
    task :update_clients, :directory do |t, args|
     require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:update_clients[<'directory'>]
USAGE_TEXT

      CLIENT_NAME_COLUMN = 'name'
      UPLOAD_REFERENCE_COLUMN = 'upload_reference'
      CENTER_COLUMN = 'center'
      BRANCH_COLUMN = 'branch'
      CASTE_COLUMN = 'caste'
      RELIGION_COLUMN = 'religion'
      PSL_COLUMN = 'psl'
      SUB_PSL_COLUMN = 'sub_psl'
      LOAN_PURPOSE_COLUMN = 'loan_purpose'
      OCCUPATION_COLUMN = 'occupation'
      LAN_COLUMN = 'lan'

      results = {}
      instance_file_prefix_client = 'update_clients_data' + '_' + DateTime.now.to_s
      results_file_name_client = File.join(Merb.root, instance_file_prefix_client + ".results")
      begin

        dir_name_str = args[:directory]
        raise ArgumentError, USAGE unless (dir_name_str and !(dir_name_str.empty?))

        out_dir_name = (dir_name_str + '_out')
        out_dir = FileUtils.mkdir_p(out_dir_name)
        error_file_path_client = File.join(Merb.root, out_dir_name, instance_file_prefix_client + '_client_errors.csv')
        success_file_path_client = File.join(Merb.root, out_dir_name, instance_file_prefix_client + '_client_success.csv')

        csv_files_to_read = Dir.entries(dir_name_str)
        results = {}
        csv_files_to_read.each do |csv_loan_tab|
          next if ['.', '..'].include?(csv_loan_tab)
          file_to_read = File.join(Merb.root, dir_name_str, csv_loan_tab)
          file_result = {}

          file_options = {:headers => true}
          client_ids_read = []; clients_not_found = []; client_ids_updated = []; client_errors = [];
          FasterCSV.foreach(file_to_read, file_options) do |row|
            client_name = row[CLIENT_NAME_COLUMN]; upload_reference = row[UPLOAD_REFERENCE_COLUMN]; center = row[CENTER_COLUMN]; branch = row[BRANCH_COLUMN]; caste_str = row[CASTE_COLUMN];
            religion_str = row[RELIGION_COLUMN]; psl_str = row[PSL_COLUMN]; sub_psl_category = row[SUB_PSL_COLUMN]; loan_purpose_str = row[LOAN_PURPOSE_COLUMN]; occupation_str = row[OCCUPATION_COLUMN];
            lan = row[LAN_COLUMN];

            client = nil
            client = Client.first(:name => client_name, :upload_reference => upload_reference)
            unless client
              client_errors << [client_name, upload_reference, "client not found"]
              clients_not_found << [client_name]
              next
            end
            client_ids_read << [client.id]

            #updating client fields.
            client.caste = caste_str.downcase.to_sym
            client.religion = religion_str.downcase.to_sym
            client.save!

            if client.saved?
              client_ids_updated << [client.id, client.upload_reference, client.caste.to_s.capitalize, client.religion.to_s.capitalize]
            else
              client_errors << [client.id, client.upload_reference, "Client cannot be saved because: #{client.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"]
            end
          end

          #creating error file for client.
          unless client_errors.empty?
            FasterCSV.open(error_file_path_client, "a") { |fastercsv|
              client_errors.each do |error|
                fastercsv << error
              end
            }
          end

          FasterCSV.open(success_file_path_client, "a") { |fastercsv|
            client_ids_updated.each do |cid|
              fastercsv << cid
            end
          }

          file_result[:client_ids_read] = client_ids_read
          file_result[:client_ids_updated] = client_ids_updated
          file_result[:clients_not_found] = clients_not_found
          file_result[:client_errors] = client_errors
          file_result[:error_file_path_client] = error_file_path_client
          file_result[:success_file_path_client] = success_file_path_client

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