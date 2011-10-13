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
    desc "This rake task generates the Common Data Format for integration with Highmark"
    task :generate do
      report = Highmark::CommonDataFormat.new({}, {:date => Date.today}, User.first)
      data = report.generate()
      folder = File.join(Merb.root, "doc", "csv", "reports")      
      # FileUtils.mkdir_p(folder)
      # filename1 = File.join(folder, "#{report.name}-customer.csv")
      # filename2 = File.join(folder, "#{report.name}-address.csv")
      # filename3 = File.join(folder, "#{report.name}-accounts.csv")
      # file1 = report.get_csv(data["CNSCRD"], filename1)
      # file2 = report.get_csv(data["ADRCRD"], filename2)
      # file3 = report.get_csv(data["ACTCRD"], filename3)
      puts 
      puts "The files are stored at #{folder}"
    end
  end
end
