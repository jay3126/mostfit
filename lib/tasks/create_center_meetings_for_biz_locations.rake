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
  namespace :data_migration do
    desc "This rake task will create center meetings for BizLocations whose location level is 0"
    task :create_center_meeting, :directory do |t, args|
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:data_migration:create_center_meeting[<'directory'>]
Convert bizlocations tab in the upload file to a .csv and put them into <directory>
USAGE_TEXT

      MEETING_FREQUENCY_COLUMN = 'meeting_frequency'
      MEETING_TIME_IN_24_HOUR_FORMAT_COLUMN = 'meeting_time_in_24_hour_format'
      CENTER_DISBURSAL_DATE_COLUMN = 'center_disbursal_date'
      CREATION_DATE_COLUMN = 'creation_date'
      BIZLOCATION_NAME_COLUMN = 'name'

      results = {}
      instance_file_prefix = 'create_center_meeting_for_biz_locations' + '_' + DateTime.now.to_s
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
        csv_files_to_read.each do |csv_biz_location_tab|
          next if ['.', '..'].include?(csv_biz_location_tab)
          file_to_read = File.join(Merb.root, dir_name_str, csv_biz_location_tab)
          file_result = {}

          file_options = {:headers => true}
          biz_locations_ids_read = []; biz_locations_not_found = []; biz_locations_ids_updated = []; errors = []
          FasterCSV.foreach(file_to_read, file_options) do |row|
            meeting_frequency_str = row[MEETING_FREQUENCY_COLUMN]
            meeting_time_str = row[MEETING_TIME_IN_24_HOUR_FORMAT_COLUMN]
            center_disbursal_date_str = row[CENTER_DISBURSAL_DATE_COLUMN]
            creation_date_str = row[CREATION_DATE_COLUMN]
            biz_location_name = row[BIZLOCATION_NAME_COLUMN]

            meeting_frequency = nil
            begin
              meeting_frequency = meeting_frequency_str.downcase
            rescue => ex
              errors << [biz_location_name, meeting_frequency_str, "meeting frequency not parsed"]
              next
            end

            meeting_time_begins_hours = meeting_time_begins_minutes = nil
            begin
              meeting_time_begins_hours, meeting_time_begins_minutes = meeting_time_str.split(":")[0..1]
            rescue => ex
              errors << [biz_location_name, meeting_time_str, "meeting time not parsed"]
              next
            end

            center_disbursal_date = nil
            begin
              center_disbursal_date = Date.parse(center_disbursal_date_str)
            rescue => ex
              errors << [biz_location_name, center_disbursal_date, "center disbursal date not parsed"]
              next
            end

            creation_date = nil
            begin
              creation_date = Date.parse(creation_date_str)
            rescue => ex
              errors << [biz_location_name, creation_date_str, "creation date not parsed"]
              next
            end

            if (creation_date.year < 1900)
              p "WARNING!!! WARNING!!! WARNING!!!"
              p "Date from the file is being read in the ancient past, for the year #{creation_date.year}"
              p "Hit Ctrl-C to ABORT NOW otherwise 2000 years are being added to this date as a correction"
              creation_date = Date.new(creation_date.year + 2000, creation_date.mon, creation_date.day)
            end
            
            if (center_disbursal_date.year < 1900)
              p "WARNING!!! WARNING!!! WARNING!!!"
              p "Date from the file is being read in the ancient past, for the year #{center_disbursal_date.year}"
              p "Hit Ctrl-C to ABORT NOW otherwise 2000 years are being added to this date as a correction"
              as_on_date = Date.new(center_disbursal_date.year + 2000, center_disbursal_date.mon, center_disbursal_date.day)
            end

            biz_location = nil
            biz_location = BizLocation.first(:name => biz_location_name, "location_level.level" => 0) if biz_location_name
            unless biz_location
              errors << [biz_location, "biz_location not found"]
              biz_locations_not_found << [biz_location]
              next
            end
            biz_locations_ids_read << [biz_location.id]
              
            #creating meeting schedules and calendar for centers.
            meeting_number = (Date.today - creation_date).to_i + Constants::Time::DEFAULT_FUTURE_MAX_DURATION_IN_DAYS
            msi = MeetingScheduleInfo.new(meeting_frequency, center_disbursal_date, meeting_time_begins_hours.to_i, meeting_time_begins_minutes.to_i)
            meeting_facade = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, User.first)
            center_meetings = meeting_facade.setup_meeting_schedule(biz_location, msi, meeting_number)

            if center_meetings.count > 0
              biz_locations_ids_updated << [biz_location.id, biz_location.name, "Meetings successsfully created."]
            else
              errors << [biz_location.id, biz_location.name, "Meetings cannot be created because: #{biz_location.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"]
            end
          end

          unless errors.empty?
            FasterCSV.open(error_file_path, "a") { |fastercsv|
              errors.each do |error|
                fastercsv << error
              end
            }
          end

          FasterCSV.open(success_file_path, "a") { |fastercsv|
            biz_locations_ids_updated.each do |bzid|
              fastercsv << bzid
            end
          }

          file_result[:biz_locations_ids_read] = biz_locations_ids_read
          file_result[:biz_locations_ids_updated] = biz_locations_ids_updated
          file_result[:biz_locations_not_found] = biz_locations_not_found
          file_result[:errors] = errors
          file_result[:error_file_path] = error_file_path
          file_result[:success_file_path] = success_file_path

          results[csv_biz_location_tab] = file_result
        end

        p results

      rescue => ex
        p "An exception occurred: #{ex}"
        p USAGE
      end
    end
  end
end
