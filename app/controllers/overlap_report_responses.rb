class OverlapReportResponses < Application

  def index
    render
  end
 
  def upload_response
    # this deals with an XML upload.
    # since the XML upload changes the data in the system, it would be very useful to track all these changes
    # and keep a copy of the XML file as well
    # TODO: to check the uploaded file for MIME type matching and file types
    @errors = {}
    @errors['File'] = "Please select file" if params[:file].blank?
    @errors['File'] = "Invalid file selection" if params[:file][:content_type] && params[:file][:content_type] != "text/xml"
    if @errors.blank?
      if params[:file][:tempfile]
        begin
          message = {}
          responses = []
          folder = File.join(Merb.root, "docs","highmark","responses")
          filename = params[:file][:filename]
          #filename = "highmark-response-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%s')}.xml"
          FileUtils.mkdir_p(folder)
          filepath = File.join(folder, filename)
          FileUtils.mv(params[:file][:tempfile].path, filepath)
          message[:notice] = "File uploaded successfully"
          @responses = nil

          @data = Crack::XML.parse(File.read(filepath))
          reports = [@data["OVERLAP_REPORT_FILE"]["OVERLAP_REPORTS"]["OVERLAP_REPORT"]].flatten
          OverlapReportResponse.transaction do |t|
            results = reports.map do |ol|
              loan_application_id = ol["REQUEST"]["MBR_ID"]
              loan_application =  LoanApplication.get(loan_application_id)
              next if loan_application.nil?
              response = OverlapReportResponse.new()
              response.loan_application_id = loan_application.id
              response.created_by_user_id = session.user.id
              response.response_text = ol.to_json
              responses << response
              response.process_response
            end
        
            if results.include?(false)
              t.rollback
              message[:error] = "The responses were NOT recorded successfully"
            else
              @responses = responses
              message[:success] = "The responses have been successfully recorded"
            end
          end
        rescue => ex
          @errors['File'] = "There is some problem in file: #{ex.message}"
        end
      end
    end
    render :index, :message => message
  end

  def show(id)
    @overlap_report_response = OverlapReportResponse.get(id)
    raise NotFound unless @overlap_report_response
    display @overlap_report_response
  end
 
end
