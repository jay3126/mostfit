class Funders < Application
  provides :xml, :yaml, :js

  def index
    @funders = @funders || Funder.all
    display @funders
  end

  def show(id)
    @funder ||= Funder.get(id)
    raise NotFound unless @funder
    @funding_lines = @funder.funding_lines
    @portfolios    = @funder.portfolios
    display [@funder, @funding_lines]
  end

  def new
    only_provides :html
    @funder = Funder.new
    display @funder
  end

  def create(funder)
    @funder = Funder.new(funder)
    if @funder.save
      redirect resource(@funder), :message => {:notice => "Funder #{@funder.name} was successfully created"}
    else
      render :new
    end
  end

  def edit(id)
    only_provides :html
    @funder = Funder.get(id)
    raise NotFound unless @funder
    display @funder
  end

  def update(id, funder)
    @funder = Funder.get(id)
    raise NotFound unless @funder
    if @funder.update_attributes(funder)
      redirect resource(@funder), :message => {:notice => "Funder #{@funder.name} was successfully updated"}
    else
      display @funder, :edit
    end
  end

  def funding_lines_tranches
    funding_line_id = params[:funding_line_id]
    unless funding_line_id.blank?
      funding_line = FundingLine.get funding_line_id
      tranches = funding_line.tranches
      return("<option value=''> Select tranch </option>"+tranches.map{|tranch| "<option value=#{tranch.id}>#{tranch.name}"}.join)
    else
      return("<option value=''> Select tranch </option>")
    end
  end
  
end
