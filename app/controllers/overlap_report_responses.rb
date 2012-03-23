class OverlapReportResponses < Application

  def index
    render
  end
 
  def upload_response
    # this deals with an XML upload.
    # since the XML upload changes the data in the system, it would be very useful to track all these changes
    # and keep a copy of the XML file as well
    if params[:file][:tempfile]
      folder = File.join(Merb.root, "docs","highmark","responses")
      filename = params[:file][:filename]
      #filename = "highmark-response-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%s')}.xml"
      FileUtils.mkdir_p(folder)
      FileUtils.mv(params[:file][:tempfile].path, File.join(folder, filename))
      
      redirect url(:controller => :overlap_report_responses, :action => :index), :message => {:notice => "File uploaded succesfully"}
      
    end
  end
 
end
