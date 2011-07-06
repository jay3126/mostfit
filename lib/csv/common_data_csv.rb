module Csv
  module CommonDataCSV

    def get_csv(data)
      folder = File.join(Merb.root, "doc", "csv", "reports")
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "#{self.name}.csv")
      file = File.new(filename, "w")
      CSV::Writer.generate(file) do |csv|
        data.each do |datum|
          csv << datum
        end
      end
      return file
    end

  end
end
