# This file is required because we cannot require "roo" in the Merb application due to some conflicting names (Log4R::Logger conflicts with ruby Logger).

require "rubygems"
require "roo"


def read_data(directory, filename)
  excel = Excel.new(File.join(directory, filename))

  #we now process the second sheet for importing categories,sub categories and types
  # excel.default_sheet = excel.sheets[1]
  excel.sheets.each { |sheet|
    excel.default_sheet=sheet
    unless File.exists?(File.join("asset_registers", "#{sheet}.csv"))
      excel.to_csv(File.join("asset_registers", "#{sheet}.csv"))
    end
  }

    end


    read_data(ARGV[0], ARGV[1])

