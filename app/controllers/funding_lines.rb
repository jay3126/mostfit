class FundingLines < Application
  include DateParser
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js

  def index
    @funding_lines = @funder.funding_lines
    display @funding_lines
  end

  def show(id)
    @funding_line = FundingLine.get(id)    
    raise NotFound unless @funding_line
    display @funding_line
  end

  def new
    only_provides :html
    @funding_line = FundingLine.new
    display @funding_line
  end

  def create(funding_line)
    funding_line[:interest_rate] = funding_line[:interest_rate].to_f / 100
    @funding_line = FundingLine.new(funding_line)
    @funding_line.funder = @funder
    if @funding_line.save
      redirect resource(@funder), :message => {:notice => "Funding Line was successfully created"}
    else
      redirect url("funders/#{@funder.id}/funding_lines/new"), :message => {:error => "Funding Line failed to be created because: #{@funding_line.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  def edit(id)
    only_provides :html
    @funding_line = FundingLine.get(id)
    @funder = @funding_line.funder
    raise NotFound unless @funding_line
    display @funding_line
  end

  def update(id, funding_line)
    funding_line[:interest_rate] = funding_line[:interest_rate].to_f / 100
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    @funder = Funder.get(params[:funder_id])
    if @funding_line.update_attributes(funding_line)
      redirect url("funders/#{@funder.id}/funding_lines/#{@funding_line.id}"), :message => {:notice => "Funding Line details updated successfully"}
    else
      redirect url("funders/#{@funder.id}/funding_lines/#{@funding_line.id}/edit"), :message => {:error => "Details of Funding Line cannot be updated because: #{@funding_line.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  # used from the router to redirect to a resourceful url
  def redirect_to_show(id)
    raise NotFound unless @funding_line = FundingLine.get(id)
    redirect resource(@funding_line.funder, @funding_line)
  end


  private
  # this works from proper resourceful urls
  def get_context
    if params[:id]
      @funding_line = FundingLine.get(params[:id])
      raise NotFound unless @funding_line
    elsif params[:funder_id]
      @funder = Funder.get(params[:funder_id])
      raise NotFound unless @funder
    end      
  end
end # FundingLines
