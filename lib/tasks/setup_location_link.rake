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
    desc "create location link record for mapping two location each other on different levels"
    task :setup_location_link do |t, args|
      require 'date'

      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:daily:setup_location_link
Create location mappging between locations
USAGE_TEXT

      begin
        LOCATION_NAME = {Region => Area, Area => Branch, Branch => Center}
        LOCATION_NAME.each do |level_name, value|
          locations = level_name.all
          parent_location_level = LocationLevel.first :name => level_name.to_s
          child_location_level = LocationLevel.first :name => value.to_s
          locations.each do |parent|
            childrens = parent.send(value.to_s.pluralize.downcase)
            childrens.each do |child|
              biz_parent = parent_location_level.biz_locations(:name => parent.name).first
              biz_child = child_location_level.biz_locations(:name => child.name).first
              LocationLink.assign(biz_child, biz_parent)
            end
          end
        end

        # Create Location mapping between two biz location
        # TBD

      rescue => ex
        puts "An error occurred: #{ex.message}"
        puts USAGE
      end
    end
  end
end
