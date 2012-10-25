class BookKeepings < Application
  # provides :xml, :yaml, :js

  def index
    render :index
  end

  def eod_process
    @locations = BizLocation.all('location_level.level' => 1)
    location_ids = @locations.map(&:id)
    on_date = get_effective_date
    created_on = get_effective_date
    EodProcess.create_default_eod_for_location(location_ids, on_date, created_on)
    display @locations
  end

  def bod_process
    @locations = BizLocation.all('location_level.level' => 1)
    location_ids = @locations.map(&:id)
    on_date = get_effective_date
    created_on = get_effective_date
    EodProcess.create_default_eod_for_location(location_ids, on_date, created_on)
    display @locations
  end

  def perform_eod_process
    message           = {:error => [], :notice => []}
    @locations        = BizLocation.all('location_level.level' => 1)
    location_ids      = params[:location_ids]
    user_id           = session.user.id
    staff_id          = session.user.staff_member.id
    on_date           = get_effective_date
    @perform_location = location_ids.blank? ? [] : @locations.select{|s| location_ids.include?(s.id)}
    message[:error]   = "Please Select Branch For EOD Process" if location_ids.blank?
    message[:notice]  = "EOD Process Started" if message[:error].blank?
    if message[:error].blank?
      EodProcess.eod_process_for_location(location_ids, staff_id, user_id, on_date)
    end
    message[:error].blank? ? message.delete(:error) : message.delete(:notice)
    redirect :eod_process, :message => message
  end

end # BookKeeping
