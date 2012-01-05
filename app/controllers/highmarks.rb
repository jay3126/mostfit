class Highmarks < Application

  def index
    folder =     File.join(Merb.root, "docs","highmark","responses")
    @files = Dir.glob(File.join(folder, "*xml"))
    render
  end

  def fix_loans
    # checks which loans have status applied and no highmark response associated
    @loans = LoanHistory.latest.map{|x| x.loan_id if x.status == :applied}.compact
    @loans.each do |l|
      l.create_highmark_response
    end
  end

  def pipe_delimited_file
    # find all the clients
    clients = Client.all(:id => Highmark::HighmarkResponse.all(:status => :pending).aggregate(:client_id))
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
    if params[:file][:tempfile]
      folder =     File.join(Merb.root, "docs","highmark","responses")
      filename = "highmark-response-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%s')}.xml"
      FileUtils.mkdir_p(folder)
      FileUtils.mv(params[:file][:tempfile].path, File.join(folder, filename))
      redirect url(:controller => :highmarks, :action => :index), :message => {:notice => "File uploaded succesfully"}
    end
  end

  def parse
    folder =     File.join(Merb.root, "docs","highmark","responses")
    @data = Crack::XML.parse(File.read(File.join(folder, params[:filename])))
    if request.method == :get
      display @data
    else
      message = {:error => "", :notice => ""}
      reports = [@data["OVERLAP_REPORT_FILE"]["OVERLAP_REPORTS"]["OVERLAP_REPORT"]].flatten
      reports.each do |ol|
        #ol = olp[1]
        reference = ol["REQUEST"]["REFERENCE"]
        loan_id = ol["REQUEST"]["LOAN_ID"]
        loan = Loan.get(loan_id)
        r = Highmark::HighmarkResponse.first(:loan_id => loan_id, :status => :pending)
        next unless r
        r.response_text = ol.to_json
        r.status = :success
        r.save
      end
    end
  end
  
  def response(id)
    @response = Highmark::HighmarkResponse.get(id)
    raise NotFound unless @response
    @loan = @response.loan
    display @response
  end
end
