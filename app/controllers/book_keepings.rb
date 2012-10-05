class BookKeepings < Application
  # provides :xml, :yaml, :js

  def index
    render :index
  end

  def eod_process
    @locations = BizLocation.all('location_level.level' => 1)
    display @locations
  end

  def perform_eod_process
    message           = {:error => [], :notice => []}
    @locations        = BizLocation.all('location_level.level' => 1)
    location_ids      = params[:location_ids]
    @perform_location = location_ids.blank? ? [] : @locations.select{|s| location_ids.include?(s.id)}
    message[:error]   = "Please Select Branch For EOD Process" if location_ids.blank?
    message[:notice]  = "EOD Process Started" if message[:error].blank?
    message[:error].blank? ? message.delete(:error) : message.delete(:notice)
    redirect :eod_process, :message => message
  end

end # BookKeeping
