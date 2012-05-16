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
  namespace :meta do

    desc "write a list of models in the application to a file, optionally listing report models separately"
    task :list_models, :and_reports do |t, args|
      require 'fastercsv'
      USE = <<USAGE_TEXT
[bin/]rake mostfit:meta:list_models[<'yes'>]
Writes out a list of the current models in Mostfit
Pass 'yes' optionally as an argument to write 'suspected' report models out to a separate file
USAGE_TEXT

      output_file_prefix = 'all_models'; output_file_suffix = '.txt'
      fq_file_name       = nil

      begin

        list_reports_separately = args[:and_reports] == 'yes' ? true : false
        models_list             = DataMapper::Model.descendants.collect { |model| model.name }
        reports_list            = []
        if list_reports_separately
          reports_list = models_list.select { |mdl| mdl.end_with?('Report') }
        end
        reduced_models_list = models_list - reports_list

        fq_file_name = File.join(Merb.root, output_file_prefix + '.as_of.' + Date.today.to_s + output_file_suffix)
        FasterCSV.open(fq_file_name, "w") { |fastercsv|
          reduced_models_list.sort.each do |row|
            fastercsv << row
          end
        }
        puts "The list of models is saved at the location: ", fq_file_name

        if list_reports_separately
          output_file_prefix = 'all_reports'
          fq_file_name       = File.join(Merb.root, output_file_prefix + '.as_of.' + Date.today.to_s + output_file_suffix)
          FasterCSV.open(fq_file_name, "w") { |fastercsv|
            reports_list.sort.each do |row|
              fastercsv << row
            end
          }
          puts "The list of report models is saved at the location: ", fq_file_name
        end

      end
    end

  end
end
