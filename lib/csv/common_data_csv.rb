module Csv
  
  def get_csv(data, filename)
    file = File.new(filename, "w")
    CSV::Writer.generate(file) do |csv|
      data.each do |datum|
        csv << datum
      end
    end
    file.close
    return file
  end
  
end
