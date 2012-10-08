class NewFunders < Application

  def index
    @funders = NewFunder.all
    render
  end

  def show
    @funder ||= NewFunder.get(params[:id])
    raise NotFound unless @funder
    @funding_lines = @funder.new_funding_lines
    display [@funder, @funding_lines]
  end

  def new
    @funder = NewFunder.new
    display @funder
  end

  def create
    message = {}
    begin
      @funder = NewFunder.new({:name => params[:name], :created_by => session.user.id})
      if @funder.save
        message = {:notice => "Funder: #{@funder.name} was successfully created"}
      else
        message = {:error => @funder.errors.collect{|error| error}.flatten.join(', ')}
      end
    rescue => ex
      message = {:error => "An error has occured: #{ex.message}"}
    end
    redirect resource(:new_funders), :message => message
  end

  def edit
    @funder = NewFunder.get(params[:id])
    raise NotFound unless @funder
    display @funder
  end

  def update
    @funder = NewFunder.get(params[:id])
    raise NotFound unless @funder
    if @funder.update_attributes(params[:new_funder])
      redirect resource(:new_funders), :message => {:notice => "Funder #{@funder.name} was successfully updated"}
    else
      display @funder, :edit
    end
  end

end