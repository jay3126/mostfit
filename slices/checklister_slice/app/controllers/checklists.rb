class ChecklisterSlice::Checklists < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    # @perform_checklist_link=generate_perform_checklist_link(session.user.role)
    #extracting data from parameters we get....

    # check if required parameters are passed or not...
    begin
      verify_parameters(params)

      #debugger
      @checklist_type=ChecklistType.get(params[:checklist_type_id].to_i)


      @target_entity_id=params[:target_entity_id]
      @target_entity_type=params[:target_entity_type]
      @target_entity_name=params[:target_entity_name]
      @loc1_type=params[:loc1_type]
      @loc2_type=params[:loc2_type]
      @loc1_id=params[:loc1_id]
      @loc2_id=params[:loc2_id]
      @loc2_name=params[:loc2_name]
      @loc1_name=params[:loc1_name]

      @no_of_applications=params[:no_of_applications]
      @effective_date=params[:effective_date]
      @staff_id=params[:staff_id]
      @staff_name=params[:staff_name]
      @referral_url=params[:referral_url]

      @checklists = @checklist_type.checklists
      @responses = @checklists.blank? ? [] : @checklists.first.get_responses(@target_entity_type, @target_entity_id)
      #@checklists=Checklist.all
      if @responses.blank?
        redirect url(:checklister_slice_fill_in_checklist, @checklists.first, params)
      else
        display @checklists
      end
      
    rescue TargetEntityNotFoundException => e
      message={:error => e.message}
      redirect params[:referral_url], :message => message

    rescue StaffNotFoundException => e
      message={:error => e.message}
      redirect params[:referral_url], :message => message

    rescue LocationNotFoundException => e
      message={:error => e.message}
      redirect params[:referral_url], :message => message

    rescue UrlNotFoundException => e

      message={:error => e.message}
      redirect url("browse/index"), :message => message

    end


  end

  def show(id)
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    display @checklist
  end

  def new
    only_provides :html
    @checklist = Checklist.new
    display @checklist
  end

  def edit(id)
    only_provides :html
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    display @checklist
  end

  def create(checklist)
    @checklist = Checklist.new(checklist)
    if @checklist.save
      redirect resource(@checklist), :message => {:notice => "Checklist was successfully created"}
    else
      message[:error] = "Checklist failed to be created"
      render :new
    end
  end

  def update(id, checklist)
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    if @checklist.update(checklist)
      redirect resource(@checklist)
    else
      display @checklist, :edit
    end
  end

  def destroy(id)
    @checklist = Checklist.get(id)
    raise NotFound unless @checklist
    if @checklist.destroy
      redirect resource(:checklists)
    else
      raise InternalServerError
    end
  end

  def fill_in_checklist(id)
    @checklist = Checklist.get(id)
    @checklist_type=@checklist.checklist_type

    @target_entity_id=params[:target_entity_id]

    @target_entity_type=(params[:target_entity_type])

    @loc1_type=(params[:loc1_type])
    @loc2_type=(params[:loc2_type])
    @loc1_id=params[:loc1_id]
    @loc2_id=params[:loc2_id]
    @no_of_applications=params[:no_of_applications]
    @effective_date=params[:effective_date]
    @staff_id=params[:staff_id]
    @staff_name=params[:staff_name]
    @referral_url=params[:referral_url]

    @sections=@checklist.sections


    display @checklist

  end

  def capture_checklist_data
    #find for which checklist is data being captured
    @checklist=Checklist.get(params[:checklist_id])
    @checklist_type=ChecklistType.get(@checklist.checklist_type_id)


    parameter_hash=Hash.new
    parameter_hash[:checklist_type_id]=@checklist_type.id
    parameter_hash[:checklist_area]= 'healthcheck'
    parameter_hash[:checklist_master_version]= '1.0'
    parameter_hash[:target_entity_type] = params[:target_entity_type]
    parameter_hash[:target_entity_name]= params[:target_entity_name]
    parameter_hash[:target_entity_id]= params[:target_entity_id]
    parameter_hash[:loc1_type]= params[:loc1_type]
    parameter_hash[:loc1_name]= params[:loc1_name]
    parameter_hash[:loc1_id]= params[:loc1_id]
    parameter_hash[:loc2_type]= params[:loc2_type]
    parameter_hash[:loc2_name]= params[:loc2_name]
    parameter_hash[:loc2_id]= params[:loc2_id]
    parameter_hash[:no_of_applications]= params[:no_of_applications]
    parameter_hash[:effective_date]= params[:effective_date]
    parameter_hash[:staff_id]= params[:staff_id]
    parameter_hash[:staff_name]= params[:staff_name]
    parameter_hash[:staff_role]= "support"
    parameter_hash[:referral_url]= params[:referral_url]

    if @checklist_type.name == "Surprise Center Visit"
      VisitSchedule.create(:visit_scheduled_date => Date.today(),:visited_on => Date.today(),:staff_member_id => session.user.id, :biz_location_id => params[:loc2_id] )
    end

    #capturing meta-data
    #creating object for who filled the checklist
    @filler=Filler.first_or_create(:name => params[:staff_name], :role => session.user.role, :type => params[:filler_type], :model_record_id => params[:staff_id].to_i)

    #create target enitity
    @target_entity=TargetEntity.first_or_create(:name => params[:target_entity_name], :type => params[:target_entity_type], :model_record_id => params[:target_entity_id].to_i)

    if !params[:result_status].blank?
      if params[:result_status].to_i==1
        @result_status="cleared"
      else
        @result_status="pending"
      end
    else
      @result_status="cleared"

    end


    begin
      #find all sections of that checklist
      @sections=@checklist.sections

      @sections.each do |section|
        #check for validations...
        # an exception should be raised if any yes/no answers are blank
        #section.checkpoints.each do |checkpoint|
        #  if params["checkpoint_#{checkpoint.id}".to_sym].blank?
        #    raise Exception
        #  end
        #end
        if @checklist.checklist_type.is_cc_checklist? && params[:target_entity_type] == 'Client'
          raise Exception, "Client Phone Number cannot be blank" if Client.get(params[:target_entity_id]).telephone_number.blank?
        end
        section.dropdownpoints.each do |drop_down|
          if params["drop_down_point_#{drop_down.id}".to_sym].to_i==0
            raise Exception, "Please select value for #{drop_down.name}"
          end
        end

      end

      if @checklist_type.is_hc_checklist?
        @response=Response.first(:target_entity_id => @target_entity.id, :checklist_id => @checklist.id)
        if @response.blank?
          @response=Response.create!(:target_entity_id => @target_entity.id, :filler_id => @filler.id, :checklist_id => @checklist.id, :value_date => Date.parse(params[:effective_date]), :created_at => Date.today, :completion_status => "complete", :result_status => @result_status.to_s)
        end
      else
        @response=Response.create!(:target_entity_id => @target_entity.id, :filler_id => @filler.id, :checklist_id => @checklist.id, :value_date => Date.parse(params[:effective_date]), :created_at => Date.today, :completion_status => "complete", :result_status => @result_status.to_s)
      end

      ChecklistLocation.first_or_create(:location_id => params[:loc1_id], :type => params[:loc1_type], :response_id => @response.id, :name => params[:loc1_name], :created_at => Date.today)
      ChecklistLocation.first_or_create(:location_id => params[:loc2_id], :type => params[:loc2_type], :response_id => @response.id, :name => params[:loc2_name], :created_at => Date.today)

      @sections.each do |section|


        #if the control comes here....the validations have passed.


        #save all the yes/no questions
        section.checkpoints.each do |checkpoint|
          if !params["checkpoint_#{checkpoint.id}".to_sym].blank?
            if @checklist_type.is_hc_checklist?
              @checkpoint_filling= checkpoint.checkpoint_fillings.first(:response_id => @response.id)
              if @checkpoint_filling.blank?
                @checkpoint_filling= checkpoint.checkpoint_fillings.create!(:status => params["checkpoint_#{checkpoint.id}".to_sym], :response_id => @response.id)
              end
            else
              @checkpoint_filling= checkpoint.checkpoint_fillings.create!(:status => params["checkpoint_#{checkpoint.id}".to_sym], :response_id => @response.id)
            end
          end
        end

        #save all the free texts
        section.free_texts.each do |free_text|
          if !params["free_text_#{free_text.id}".to_sym].blank?
            if @checklist_type.is_hc_checklist?
              @free_text_filling=free_text.free_text_fillings.first(:response_id => @response.id)
              if @free_text_filling.blank?
                @free_text_filling=free_text.free_text_fillings.create!(:comment => params["free_text_#{free_text.id}".to_sym], :response_id => @response.id)
              end
            else
              @free_text_filling=free_text.free_text_fillings.create!(:comment => params["free_text_#{free_text.id}".to_sym], :response_id => @response.id)
            end
          end
        end

        #save all drop downs
        section.dropdownpoints.each do |drop_down|
          if @checklist_type.is_hc_checklist?
            @dropdownpoint_filling=drop_down.dropdownpoint_fillings.first(:response_id => @response.id)
            if @dropdownpoint_filling.blank?
              @dropdownpoint_filling=drop_down.dropdownpoint_fillings.create!(:model_record_id => params["drop_down_point_#{drop_down.id}".to_sym].to_i, :response_id => @response.id, :model_record_name => Kernel.const_get(drop_down.model_name).get(params["drop_down_point_#{drop_down.id}".to_sym].to_i).name)
            end
          else
            @dropdownpoint_filling=drop_down.dropdownpoint_fillings.create!(:model_record_id => params["drop_down_point_#{drop_down.id}".to_sym].to_i, :response_id => @response.id, :model_record_name => Kernel.const_get(drop_down.model_name).get(params["drop_down_point_#{drop_down.id}".to_sym].to_i).name)
          end
        end

        #save all checkbox points
        section.checkboxpoints.each do |checkbox_point|
          checkbox_point.checkboxpoint_options.each do |option|
            if !params["option#{option.id}".to_sym].blank?
              if @checklist_type.is_hc_checklist?
                @checkboxpoint_option_filling=option.checkboxpoint_option_fillings.first(:response_id => @response.id)
                if @checkboxpoint_option_filling.blank?
                  @checkboxpoint_option_filling=option.checkboxpoint_option_fillings.create!(:status => params["option#{option.id}".to_sym].to_i, :response_id => @response.id)
                end
              else
                @checkboxpoint_option_filling=option.checkboxpoint_option_fillings.create!(:status => params["option#{option.id}".to_sym].to_i, :response_id => @response.id)
              end
            end
          end
        end


      end

    rescue Exception => e
      message={:error => e.message}
      redirect url(:checklister_slice_fill_in_checklist, @checklist, params), :message => message

    else


      redirect url(:checklister_slice_checklists, parameter_hash)
    end


    #@sample=params
    #display @sample


  end


  def edit_checklist_data

    message = {}
    @checklist = Checklist.get params[:checklist_id]
    @checkpoint_fillings = params[:checkpoint_fillings]||[]
    @checkpoint_fillings.each do |checkpoint_filling_id, value|
      id = checkpoint_filling_id.split("_").last
      CheckpointFilling.get(id).update(:status => value)
    end

    @checkboxpoint_option_fillings = params[:checkboxpoint_option_fillings]||[]
    @checkboxpoint_option_fillings.each do |checkboxpoint_option_filling_id, value|
      id = checkboxpoint_option_filling_id.split("_").last
      CheckboxpointOptionFilling.get(id).update(:status => value)
    end

    @free_text_fillings_t2 = params[:free_text_fillings_t2]||[]
    @free_text_fillings_t2.each do |free_text_filling_id, value|
      id = free_text_filling_id.split("_").last
      FreeTextFilling.get(id).update(:comment => value)
    end

    @free_text_fillings_t1n3 = params[:free_text_fillings_t1n3]||[]
    @free_text_fillings_t1n3.each do |free_text_filling_id, value|
      id = free_text_filling_id.split("_").last
      FreeTextFilling.get(id).update(:comment => value)
    end

    @dropdownpoint_fillings = params[:dropdownpoint_fillings]||[]
    @dropdownpoint_fillings.each do |dropdownpoint_filling_id, value|
      id = dropdownpoint_filling_id.split("_").last
      DropdownpointFilling.get(id).update(:model_record_name => value)
    end

    Response.get(params[:result_status]).update(:result_status => 'cleared') unless params[:result_status].blank?
    if message[:error].blank?
      redirect params[:request_url], :message => {:notice => 'Checklist updated'}
    else
      redirect request.referer, :message => message
    end

  end


end # Checklists
