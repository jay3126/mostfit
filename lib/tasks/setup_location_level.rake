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
  namespace :location do
    desc "create location level and biz location record and map each other on level"
    task :setup_location_level do |t, args|
      require 'date'

      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:daily:setup_location_level
Create location level, biz_location and location_link
USAGE_TEXT

      begin
        LOCATION_NAME = [Center, Branch, Area, Region]
        level_no = 0
        LOCATION_NAME.each do |level|
          location_level = LocationLevel.create(:name => level.to_s, :level => level_no)
          locations = level.all
          level_no = level_no + 1

          locations.each do |location|
            BizLocation.create(:name => location.name.to_s, :location_level_id => location_level.id)
          end
        end

        # Create Location Level and Biz Location
        # TBD

      rescue => ex
        puts "An error occurred: #{ex.message}"
        puts USAGE
      end
    end
  end
end
