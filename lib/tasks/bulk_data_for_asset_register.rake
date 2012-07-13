#USAGE:

# rake excel:ptotem:bulk_data_for_asset_register:parse_file[<source_directory_url>,<source_file_url>]
# Please write the paths
#   - in quotes
#   - with extension
#   - with absolute paths
#please create a folder called "asset_registers"   in Merb.root.





#
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')
namespace :excel do
  namespace :ptotem do
    namespace :bulk_data_for_asset_register do
      desc "Uploads the data provided in the excel sheet to appropriate tables in the database"
      task :parse_file, [:src_dir, :src_file] do |t, args|
        filename=args[:src_file]
        directory=args[:src_dir]

        require "rubygems"
        require 'fastercsv'
        #we call this line inorder to create csvs of all sheets so we can process it !
        `ruby lib/tasks/read_excel.rb #{directory} #{filename}`

        FasterCSV.foreach(File.join("asset_registers", "Sheet2.csv"), :headers => :first_row) do |r|

          @asset_category=AssetCategory.write_data(r[2])
          @asset_sub_category=AssetSubCategory.write_data(@asset_category, r[3])
          @asset_type=AssetType.write_data(@asset_sub_category, r[4])


        end

        # we now parse sheet 1 which contains data for asset registers.

        sheet1_index=0
        FasterCSV.foreach(File.join("asset_registers", "Sheet1.csv"), :headers => [0, 1, 2]) do |r|
          if sheet1_index<=3
            sheet1_index=sheet1_index+1
            next

          end

          sheet1_index=sheet1_index+1
          argument_array=Array.new

          #location

          argument_array << r[4]
          #include category
          argument_array << r[5]
          #include sub-category
          argument_array << r[6]
          #include type
          argument_array << r[7]
          #include tag number
          argument_array << r[8]
          #include name of item
          argument_array << r[9]
          #include name of vendor
          argument_array << r[10]
          #include invoice number
          argument_array << r[11]

          #include invoice date
          argument_array << r[12]
          #include make
          argument_array << r[14]
          #include model
          argument_array << r[16]
          #include serial number
          argument_array << r[17]
          #include date
          argument_array << r[18]
         # issue date
           argument_array << r[22]




          AssetRegister.write_data(argument_array)
        end

      end
    end
  end
end
