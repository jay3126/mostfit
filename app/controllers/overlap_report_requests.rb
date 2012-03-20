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
  
end
