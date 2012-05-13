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
    task :output_center_meetings do |t, args|
      require 'fastercsv'

      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:migration:output_center_meetings
Produces a .csv file that has information about center meeting schedules as currently configured in the system
USAGE_TEXT

      DATE_FORMAT = "%d-%m-%Y"
      begin

        centers_and_meeting_days = {}
        centers_without_meeting_days = []
        all_centers = Center.all(:order =>[:id.asc])
        all_centers.each do |center|
          center_meeting_days = CenterMeetingDay.all(:center_id => center.id)
          if (center_meeting_days and (not (center_meeting_days.empty?)))
            centers_and_meeting_days[center] = center_meeting_days
          else
            centers_without_meeting_days << center
          end
        end
        centers_by_branch = all_centers.group_by {|center| center.branch.name if (center.branch and center.branch.name)}

        branch_center_meetings = {}
        centers_by_branch.each { |branch, centers|
          data_rows = []; data_rows_sorted = []
          centers.each { |center|
            center_name = center.name
            meeting_day_from_center = center.meeting_day
            meeting_days = centers_and_meeting_days[center]
            if meeting_days
              meeting_days.each { |md|
                md_weekday = Constants::Time.get_week_day(md.valid_from) || "not defined"
                row = [
                  center.id, center_name, meeting_day_from_center, md.meeting_day,
                  md.valid_from.strftime(DATE_FORMAT), md_weekday, md.valid_upto.strftime(DATE_FORMAT),
                  md.every, md.what, md.of_every, md.period, md.new_what, md.to_s
                ]
                data_rows << row
              }
              data_rows_sorted = data_rows.sort_by {|row| row.first}
            end
          }
          branch_center_meetings[branch] = data_rows_sorted
        }

        HEADER_ROW = [
          "Center ID", "Center Name", "Meeting day from center", "meeting day from center meeting day", "from", "from weekday",	"until", "every",	"what", "of_every", "period",	"new_what",	"description"
        ]

        org_name = (Mfi.first and Mfi.first.name) ? Mfi.first.name : "organisation"
        write_to_folder = File.join(Merb.root, org_name)
        FileUtils.mkdir_p(write_to_folder)
        branch_center_meetings.each { |branch, center_meetings|
          file_name = File.join(write_to_folder, "#{branch}.center_meetings.as_of_#{Date.today}.csv")
          header_was_written = false
          FasterCSV.open(file_name, "w", :force_quotes => true) { |fastercsv|
            unless header_was_written
              fastercsv << HEADER_ROW
              header_was_written = true
            end
            center_meetings.each do |row|
              fastercsv << row
            end
          }
        }

        NO_MEETINGS_HEADER_ROW = ["Branch", "Center ID", "Center name"]
        unless centers_without_meeting_days.empty?
          sorted_centers_without_meeting_days = centers_without_meeting_days.sort_by {|center| center.branch.name }
          no_center_meetings_file_name = File.join(write_to_folder, "no_center_meetings.as_of_#{Date.today}.csv")
          header_was_written = false
          FasterCSV.open(no_center_meetings_file_name, "w", :force_quotes => true) { |fastercsv|
            unless header_was_written
              fastercsv << NO_MEETINGS_HEADER_ROW
              header_was_written = true
            end
            sorted_centers_without_meeting_days.each { |center|
              fastercsv << [center.branch.name, center.id, center.name]
            }
          }
        end
      rescue => ex
        puts "Exception: #{ex}"
        puts "USAGE: #{USAGE}"
      end

    end
  end
end