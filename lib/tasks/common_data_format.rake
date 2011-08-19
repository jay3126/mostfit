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
      report = CommonDataFormat.new({}, {:date => Date.today}, User.first)
      data = report.generate()
      folder = File.join(Merb.root, "doc", "csv", "reports")      
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "#{report.name}.csv")
      file = report.get_csv(data, filename)
      puts 
      puts "The file is stored at #{folder}"
    end
  end
end
