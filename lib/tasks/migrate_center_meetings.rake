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
  namespace :migration do
    desc "prepares a list of center meetings as per the current configuration in (the to-be-obsoleted) scheme of center meeting days"
    task :migrate_center_meetings do |t, args|
      require 'fastercsv'

      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:migration:migrate_center_meetings
Migrates center meeting days from the older scheme to the new meeting schedules
USAGE_TEXT

      #TODO: current version may erroneously create only weekly meeting schedules
      begin
        centers_and_schedules = []
        CenterMeetingDay.all.each { |cmd|
          centers_and_schedules.push(cmd.to_meeting_schedule) if cmd.to_meeting_schedule
        }

        centers_and_schedules.each { |schedule_info|
          center_id = schedule_info.delete(:center_id)
          center = Center.get(center_id)

          ms = MeetingSchedule.create(schedule_info)
          center.meeting_schedules << ms
          center.save
        }

      rescue => ex
        puts "Exception: #{ex}"
        puts "USAGE: #{USAGE}"
      end

    end
  end
end
