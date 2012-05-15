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
        centers_included_from_cmd = []
        unsave_centers = []
        location_level = LocationLevel.first(:level => 0)
        CenterMeetingDay.all.each { |cmd|
          centers_and_schedules.push(cmd.to_meeting_schedule) if cmd.to_meeting_schedule
          centers_included_from_cmd.push(cmd.center.id) if (cmd.center and cmd.center.id)
        }

        centers_included_from_cmd.uniq!
        p "Centers left out number: #{centers_included_from_cmd.length}"

        centers_and_schedules.each { |schedule_info|
          center_id = schedule_info.delete(:center_id)
          center = Center.get(center_id)
          biz_location = location_level.biz_locations.first(:name => center.name)

          ms = MeetingSchedule.first_or_create(schedule_info)
          biz_location.meeting_schedules << ms
          unless biz_location.save
            unsave_centers << [biz_location.id, false, biz_location.errors.first.first]
          end
        }

        all_center_ids = Center.all.aggregate(:id)
        centers_left_out = (all_center_ids - centers_included_from_cmd).uniq
        p "Centers left out number: #{centers_left_out.length}"

        centers_left_out.each { |cid|
          center = Center.get(cid)
          biz_location = location_level.biz_locations.first(:name => center.name)
          if (center && center.meeting_day != :none && biz_location)
            meeting_day = center.meeting_day
            center_created_on = center.created_at
            defaulted_schedule_begins_on = Date.new(center_created_on.year, center_created_on.mon, center_created_on.day)
            adjusted_schedule_begins_on = Constants::Time.get_next_date_for_day(meeting_day, defaulted_schedule_begins_on)
            meeting_time_begins_hours = center.meeting_time_hours || 0
            meeting_time_begins_minutes = center.meeting_time_minutes || 0

            msi = MeetingScheduleInfo.new(MarkerInterfaces::Recurrence::WEEKLY, adjusted_schedule_begins_on, meeting_time_begins_hours, meeting_time_begins_minutes)
            ms = MeetingSchedule.from_info(msi)
            biz_location.meeting_schedules << ms
            unless biz_location.save
              unsave_centers << [biz_location.id, false, biz_location.errors.first.first]
            end
          end
        }

        unless unsave_centers.blank?
          HEADER_ROW = ["Center id", "Save","Status"]

          org_name = (Mfi.first && Mfi.first.name) ? Mfi.first.name : "Mostfit"
          write_file = File.join(Merb.root, org_name)
          FileUtils.mkdir_p(write_file)
          file_name = File.join(write_file, "center_meeting_status")
          FasterCSV.open(file_name, "w", :force_quotes => true){|fastercsv|
            fastercsv << HEADER_ROW
            unsave_centers.each do |center|
              fastercsv << center
            end
          }
        end
      rescue => ex
        puts "Exception: #{ex}"
        puts "USAGE: #{USAGE}"
      end

    end
  end
end