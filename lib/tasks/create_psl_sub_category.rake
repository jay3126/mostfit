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
    desc "This rake task will create PSL Sub-category"
    task :create_psl_sub_category, :directory do |t, args|
     require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:create_psl_sub_category[<'directory'>]
USAGE_TEXT

      PSL_COLUMN = 'psl'
      SUB_PSL_COLUMN = 'sub_psl'

      results = {}
      instance_file_prefix = 'create_psl_sub_category' + '_' + DateTime.now.to_s
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
          sub_psls_read = []; sub_psls_not_found = []; sub_psls_updated = []; sub_psls_errors = [];
          FasterCSV.foreach(file_to_read, file_options) do |row|
            psl_str = row[PSL_COLUMN]; sub_psl_category = row[SUB_PSL_COLUMN];

            psl = PrioritySectorList.first(:name => psl_str)
            psl_sub_category = PslSubCategory.new(:name => sub_psl_category, :priority_sector_list_id => psl.id)
            psl_sub_category.save

            if psl_sub_category.saved?
              sub_psls_updated << [psl_sub_category.id, psl_sub_category.name, psl_sub_category.priority_sector_list.name]
            else
              sub_psls_errors << [psl_str, sub_psl_category]
            end
          end

          unless sub_psls_errors.empty?
            FasterCSV.open(error_file_path, "a") { |fastercsv|
              sub_psls_errors.each do |error|
                fastercsv << error
              end
            }
          end

          FasterCSV.open(success_file_path, "a") { |fastercsv|
            sub_psls_updated.each do |cid|
              fastercsv << cid
            end
          }

          file_result[:sub_psls_updated] = sub_psls_updated
          file_result[:sub_psls_errors] = sub_psls_errors
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
