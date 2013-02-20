class SurpriseVisitCenters < Application
  # provides :xml, :yaml, :js

  def index
    @surprise_visit_centers = SurpriseVisitCenter.all
    @center = params[:center]
    @branch = params[:branch]
    @biz_location = params[:biz_location]
    @center_name = BizLocation.get(@center).name
    @branch_name = BizLocation.get(@branch).name
    display @surprise_visit_centers
  end

  def show(id)
    @surprise_visit_center = SurpriseVisitCenter.get(id)
    raise NotFound unless @surprise_visit_center
    display @surprise_visit_center
  end

  def new
    only_provides :html
    @surprise_visit_center = SurpriseVisitCenter.new
    @center = params[:center]
    @branch = params[:branch]
    @biz_location = params[:biz_location]
    @center_name = BizLocation.get(@center).name
    @branch_name = BizLocation.get(@branch).name
    
    display @surprise_visit_center
  end

  def edit(id)
    only_provides :html
    @surprise_visit_center = SurpriseVisitCenter.get(id)
    raise NotFound unless @surprise_visit_center
    display @surprise_visit_center
  end

  def create(surprise_visit_center)
    @surprise_visit_center = SurpriseVisitCenter.new(surprise_visit_center)
    @value_date = params[:value_date]
    @date = params[:date]
    @center = surprise_visit_center[:center]
    @branch = surprise_visit_center[:branch]
    #raise @branch.inspect
    @surprise_visit_center.attributes = {:value_date => @value_date,:date => @date, :center => @center, :branch => @branch }
    if @surprise_visit_center.save
      redirect resource(@surprise_visit_center), :message => {:notice => "SurpriseVisitCenter was successfully created"}
    else
      message[:error] = "SurpriseVisitCenter failed to be created"
      render :new
    end
  end

  def update(id, surprise_visit_center)
    @surprise_visit_center = SurpriseVisitCenter.get(id)
     @members_late = surprise_visit_center[:members_late]
     @members_absent = surprise_visit_center[:members_absent]
     @leader_was_present_at_meeting = surprise_visit_center[:leader_was_present_at_meeting]
     @center_members_followed_procedures = surprise_visit_center[:center_members_followed_procedures]
     @field_office_followed_procedures = surprise_visit_center[:field_office_followed_procedures]
     @center_leaders_attendance_utdate = surprise_visit_center[:center_leaders_attendance_utdate]
     @pbook_and_centers_uptdate = surprise_visit_center[:pbook_and_centers_uptdate]
     @no_member_paind_any_add_money = surprise_visit_center[:no_member_paind_any_add_money]
     @all_claims_settled_no_pending = surprise_visit_center[:all_claims_settled_no_pending]
     @all_center_meeting_plcae_ntchgd = surprise_visit_center[:all_center_meeting_plcae_ntchgd]
     @concern_about_center = surprise_visit_center[:concern_about_center]
     @file_update_with_previous_scvs = surprise_visit_center[:file_update_with_previous_scvs]
     @genreal_comments = surprise_visit_center[:genreal_comments]
     @customer_comments = surprise_visit_center[:customer_comments]
     @name_of_officer = surprise_visit_center[:name_of_officer] 
     @date = params[:date]
     @place = surprise_visit_center[:place]
     @value_date = params[:value_date]
     @staff_member = surprise_visit_center[:staff_member]

    @surprise_visit_center.attributes = {:members_late => @members_late }
    @surprise_visit_center.attributes = {:members_absent => @members_absent }
    @surprise_visit_center.attributes = {:leader_was_present_at_meeting => @leader_was_present_at_meeting }
    @surprise_visit_center.attributes = {:center_members_followed_procedures => @center_members_followed_procedures }
    @surprise_visit_center.attributes = {:field_office_followed_procedures => @field_office_followed_procedures }
    @surprise_visit_center.attributes = {:center_leaders_attendance_utdate => @center_leaders_attendance_utdate }
    @surprise_visit_center.attributes = {:pbook_and_centers_uptdate => @pbook_and_centers_uptdate }
    @surprise_visit_center.attributes = {:no_member_paind_any_add_money => @no_member_paind_any_add_money }
    @surprise_visit_center.attributes = {:all_claims_settled_no_pending => @ll_claims_settled_no_pending }
    @surprise_visit_center.attributes = {:all_center_meeting_plcae_ntchgd => @all_center_meeting_plcae_ntchgd }
    @surprise_visit_center.attributes = {:concern_about_center => @concern_about_center }
    @surprise_visit_center.attributes = {:file_update_with_previous_scvs => @file_update_with_previous_scvs }
    @surprise_visit_center.attributes = {:genreal_comments => @genreal_comments }
    @surprise_visit_center.attributes = {:customer_comments => @customer_comments }
    @surprise_visit_center.attributes = {:name_of_officer => @name_of_officer }
    @surprise_visit_center.attributes = {:date => @date }
    @surprise_visit_center.attributes = {:place => @place }
    @surprise_visit_center.attributes = {:value_date => @value_date }
    @surprise_visit_center.attributes = {:staff_member => @staff_member }

    raise NotFound unless @surprise_visit_center

    if @surprise_visit_center.save
       redirect resource(@surprise_visit_center)
    else
      display @surprise_visit_center, :edit
    end
  end

  def destroy(id)
    @surprise_visit_center = SurpriseVisitCenter.get(id)
    raise NotFound unless @surprise_visit_center
    if @surprise_visit_center.destroy
      redirect resource(:surprise_visit_centers)
    else
      raise InternalServerError
    end
  end

end # SurpriseVisitCenters
