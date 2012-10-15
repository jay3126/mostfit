class Uploads < Application

  before do
    if Mfi.first.system_state != :migration
      redirect(url(:admin), :message => {:error => "System must be in migration state for using the data upload functionality."})
    end
  end

  def upload_status        
    render
  end

  def index
    hash = session.user.admin? ? {} : {:user => session.user}
    @uploads = Upload.all(hash.merge(:order => [:updated_at]))
    display @uploads
  end

  def new
    @upload = Upload.new
    display @upload
  end
  
  def create
    erase = params.has_key?(:erase)
    if params[:file] and params[:file][:filename] and params[:file][:tempfile]
      file      = Upload.make(params.merge(:user => session.user))
    else
      render
    end
    redirect resource(:uploads), :message => {:notice => "File was sucessfully uploaded"}
  end

  def show(id)
    @upload = Upload.get(id)
    raise NotFound unless @upload
    display @upload
  end

  def continue(id)
    @upload = Upload.get(id)
    raise NotFound unless @upload
    Merb.run_later do
      @upload.cont
    end
    redirect resource(@upload), :message => {:notice => "Started processing. Click 'Refresh' button to check status of upload"}
  end
  
  def stop(id)
    # stops an upload that is processing
    @upload = Upload.get(id)
    raise NotFound unless @upload
    @upload.stop
    redirect resource(@upload)
  end

  def reload(id)
    # reloads a single model
    @upload = Upload.get(id)
    raise NotFound unless @upload
    Kernel.const_get(params[:model].to_s.singularize.camel_case).all(:upload_id => @upload.id).destroy!
    Merb.run_later {
      @upload.reload(params[:model])
    }
    redirect resource(@upload)
  end

  def reset(id)
    @upload = Upload.get(id)
    raise NotFound unless @upload
    options = params[:delete] ? {:erase => true} : {}
    @upload.reset(options)
    redirect resource(@upload), :message => {:notice => "This upload was succesfully reset"}
  end

  def error_log
    @upload = Upload.get(params[:id])
    raise Notfound unless @upload
    fn = File.join("uploads", @upload.directory, "#{params[:model]}_errors.csv")
    if File.exists?(fn)
      "<pre>" + File.read(fn) + "</pre>"
    else
      redirect resource(@upload), :message => {:notice => "No error's were encountered while uploading #{params[:model].to_s} data so no error log file created."}
    end
  end

  def edit(id)
    @upload = Upload.get(id)
    raise NotFound unless @upload
    display @upload
  end

  def update(id, upload)
    @upload = Upload.get(id)
    FileUtils.rm(File.join("uploads",@upload.directory,@upload.filename))
    @upload.reset # does not delete data. only removes the files
    raise NotFound unless @upload
    if params[:file] and params[:file][:filename] and params[:file][:tempfile]
      @upload.move(params[:file][:tempfile].path)
      redirect resource(@upload), :message => {:notice => "File has been replaced. Click continue to extract"}
    else
      render
    end
  end

  def show_csv(id)
    @upload = Upload.get(id)
    raise NotFound unless @upload
    "<pre>" + File.read(File.join(Merb.root, "uploads",@upload.directory, params[:filename])) + "</pre>"
  end
  
end
