class Tranches < Application
  provides :xml, :yaml, :js
  include DateParser

  def list(id)

    # GATE-KEEPING
    funding_line_id=id
    
    # VALIDATION
    if FundingLine.get(funding_line_id).nil?
      redirect("/funders", :message => {:notice => "Funding line not found"})
    end
    # OPERATIONS PERFORMED
    
    begin
      @funding_line=FundingLine.get(id)
      @tranches=@funding_line.tranches(:order => [ :date_of_commencement .asc ])
      #@tranches.sort! { |a,b| a.date_of_commencement <=> b.date_of_commencement }
    rescue => ex
      #@errors.push(ex.message)
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    
    # RENDER/RE-DIRECT
    display [@tranches,@funding_line]
  end	

  def index
	
  end
  
  def new(id)
    # GATE-KEEPING
    funding_line_id=id
    
    # VALIDATION
    if FundingLine.get(funding_line_id).nil?
      redirect(params[:return], :message => {:notice => "Funding line not found"})
    end
    # OPERATIONS PERFORMED
    
    begin
      @tranch=Tranch.new
      @tranch.funding_line_id=id
    rescue => ex
      @errors.push(ex.message)
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    
    # RENDER/RE-DIRECT
    display @tranch
  end
  
  def create(tranch)
    # GATE-KEEPING
    @errors = []
    @tranch = Tranch.new(tranch)
    @errors << "Tranch name must not be blank " if params[:tranch][:name].blank?
    @errors << "Date must not be blank " if params[:tranch][:date_of_commencement].blank?
    if @errors.empty?
      # VALIDATION
      if(Tranch.all(:name => @tranch.name,:funding_line=>@tranch.funding_line).count!=0)
        message[:error] = "Tranch with same name already exists !"
        render :new  # error messages will show
      else
        # OPERATIONS PERFORMED
        if @tranch.save
          redirect("/tranches/list/#{@tranch.funding_line_id}", :message => {:notice => "Tranch '#{@tranch.name}' (Id:#{@tranch.id}) successfully created"})
        else
          message[:error] = "Tranch failed to be created"
          render :new  # error messages will show
        end
      end
    else
      message[:error] = @errors.flatten.join(', ')
      render :new  # error messages will show
    end
  end

end