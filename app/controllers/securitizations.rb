class Securitizations < Application

  require "tempfile"



  def index
	@securitizations=Securitization.all
  display @securitizations
  end
  
  def new
	@securitization=Securitization.new
	display @securitization
  end
  
  def create(securitization)
  @securitization = Securitization.new(securitization)
	if(Securitization.all(:name => @securitization.name).count==0)
		if @securitization.save!
			redirect("/securitizations", :message => {:notice => "Securitization '#{@securitization.name}' (Id:#{@securitization.id}) successfully created"})
		else
			message[:error] = "Securitization failed to be created"
			render :new  # error messages will show
		end
	else
		message[:error] = "Securitization with same name already exists !"
		render :new  # error messages will show
	end    
  end


  def upload_data(id)
    @id=id
    @securitization=Securitization.get(id)
    @upload = Upload.new
    display @upload
  end


  def save_data

    erase = params.has_key?(:erase)
    if params[:file].to_s and params[:file][:filename].to_s and params[:file][:tempfile].path.to_s
      #File temp=File.new(params[:file][:tempfile].path.to_s)
      Securitization.move(params[:file][:tempfile].path,params[:file][:filename])
      #render :text=>params[:file][:filename]
    else
      render
    end
    redirect("/Securitizations")
  end

  
end
