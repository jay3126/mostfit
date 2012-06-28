class StaffPostings < Application

  def index
    @staff_postings = StaffPosting.all
    @staff_posting = StaffPosting.new
    if params[:location_level].blank?
      @biz_locations = BizLocation.all.select{|l| l.location_level.level != 0}
    else
      @biz_locations = LocationLevel.first(:level => params[:location_level]).biz_locations
    end
    if request.xhr?
      render :template => 'staff_postings/index', :layout => layout?
    else
      display @staff_posting
    end
  end

  def create

    # INITIALIZING VARIABLES USED THROUGHTOUT
    @message = {}

    # GATE-KEEPING
    staff_id        = params[:staff_posting][:staff_id]
    location_id     = params[:staff_posting][:at_location_id]
    performed_by_id = params[:staff_posting][:performed_by]
    effective_on    = params[:staff_posting][:effective_on]
    biz_location_id = params[:biz_location_id]
    recorded_by     = session.user.id
    
    # VALIDATIONS
    @message[:error] = "Please select Staff Member" if staff_id.blank?
    @message[:error] = "Please select Location" if location_id.blank?
    @message[:error] = "Please select Peformed By" if performed_by_id.blank?
    @message[:error] = "Effective Date cannot blank" if effective_on.blank?

    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        staff_member = StaffMember.get staff_id
        to_location = BizLocation.get location_id
        staff_posting = StaffPosting.assign(staff_member, to_location, effective_on, performed_by_id, recorded_by)
        if staff_posting.new?
          @message = {:error => "Staff Posting fail"}
        else
          @message = {:notice => "Staff posted successfully"}
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect url(:controller => :user_locations, :action => :show, :id => biz_location_id), :message => @message

  end
end
