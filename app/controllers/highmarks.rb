class Highmarks < Application

  def index
    render
  end

 def pipe_delimited_file
   clients = Client.all(:highmark_done => false)
   file = FasterCSV.generate({:col_sep => "|"}) do |csv| 
     clients.each do |client|
       csv << client.row_to_delimited_file
     end
   end

   send_data(file, :filename => "clients.csv", :type => "csv")
 end

 # def download_pipe_delimited_file
 #   send_data(File.read(filename), :filename => filename, :type => "csv")
 # end

 def process_response
   
 end
  
end
