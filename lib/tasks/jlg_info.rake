require "rubygems"

include Csv

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
  namespace :report do
    desc "Support Request #1360: particulars of JLGs"
    task :jlg_info do
      data = []
      data << [
               "ID of JLG", 
               "Name of JLG", 
               "Address of JLG", 
               "Name of Centre", 
               "Name of branch", 
               "Date of formation", 
               "No. of Members", 
               "Total loan sanctioned", 
               "Total loan disbursed", 
               "Loans Outstanding"
              ]
      ClientGroup.all.each do |x| 
        data << [
                 x.id, 
                 x.name, 
                 x.center.address.gsub("/n", " ").gsub("/r", " "), 
                 x.center.name, 
                 x.center.branch.name, 
                 x.center.creation_date, 
                 x.clients.count, 
                 (x.clients.empty? ? nil : x.clients.loans(:approved_on.not => nil).count), 
                 (x.clients.empty? ? nil : x.clients.loans(:disbursal_date.not => nil).count), 
                 (x.clients ? nil : x.clients.loans(:c_last_status => 6).count)
                ]
      end
      folder = File.join(Merb.root, "doc", "csv", "reports")      
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "icash_jlg_as_on_#{Date.today}.csv")
      file = get_csv(data, filename)
    end
  end
end
