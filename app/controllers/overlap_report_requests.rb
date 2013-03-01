class OverlapReportRequests < Application

  def index
    folder = File.join(Merb.root, "docs","highmark","requests")
    FileUtils.mkdir_p folder
    @files = Dir.glob(File.join(folder, "*csv"))
    render
  end

  def send_csv(filename)
    send_file(filename, :filename => (filename.split("/")[-1].chomp))
  end

  def request_file

    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id

    # Show Already generated request file to download
    folder = File.join(Merb.root, "docs","highmark","requests")
    FileUtils.mkdir_p folder
    @files = Dir.glob(File.join(folder, "*csv"))

    render
  end

  def generate_cb_request_file
    # INITIALIZATIONS
    @errors = []
    message = {}
    condition_hash = {}

    # GATE-KEEPING
    branch = params[:parent_location_id]
    center = params[:child_location_id]

    condition_hash.merge!(:at_branch_id => branch) unless branch.blank?
    condition_hash.merge!(:at_center_id => center) unless center.blank?

    # OPERATIONS PERFORMED
    begin
      loan_applications_facade.generate_credit_bureau_request_file(get_effective_date, condition_hash)
      message = {:notice => "Request file generated succesfully."}
    rescue => ex
      @errors << ex.message
      message = {:error => @errors.to_s}
    end

    # RENDER/RE-DIRECT
    redirect url(:controller => "overlap_report_requests", :action => "request_file", :parent_location_id => branch, :child_location_id => center), :message => message
  end

end