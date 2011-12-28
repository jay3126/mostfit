class Highmarks < Application

  def index
    debugger
    folder =     File.join(Merb.root, "docs","highmark","responses")
    @files = Dir.glob(File.join(folder, "*xml"))
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

 def upload_response
   # this deals with an XML upload.
   # since the XML upload changes the data in the system, it would be very useful to track all these changes
   # and keep a copy of the XML file as well
   debugger
   if params[:file][:tempfile]
     folder =     File.join(Merb.root, "docs","highmark","responses")
     filename = "highmark-response-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%s')}.xml"
     FileUtils.mkdir_p(folder)
     FileUtils.mv(params[:file][:tempfile].path, File.join(folder, filename))
     redirect url(:controller => :highmarks, :action => :index), :message => {:notice => "File uploaded succesfully"}
   end
 end

 def parse
   debugger
   folder =     File.join(Merb.root, "docs","highmark","responses")
   @data = Crack::XML.parse(File.read(File.join(folder, params[:filename])))
   display @data
 end

   
  
end
