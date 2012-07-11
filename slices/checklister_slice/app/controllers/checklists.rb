class ChecklisterSlice::Checklists < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    # @perform_checklist_link=generate_perform_checklist_link(session.user.role)
    #extracting data from parameters we get....
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
    #check if required parameters are passed or not...
    #if !are_parameters_correct?(params)
    #  message = {:error => "The URL is broken. Please contact your administrator."}
    #  redirect url("browse/index"), :message => message
    #
    #end

    #@checklists=Checklist.all

    display @checklists


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
    parameter_hash[:staff_role]= "support",
        parameter_hash[:referral_url]= params[:referral_url]


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
    @response=Response.create!(:target_entity_id => @target_entity.id, :filler_id => @filler.id, :checklist_id => @checklist.id, :value_date => Date.parse(params[:effective_date]), :created_at => Date.today,:completion_status=>"complete",:result_status=>@result_status.to_s)
    ChecklistLocation.first_or_create(:location_id => params[:loc1_id], :type => params[:loc1_type], :response_id => @response.id, :name => params[:loc1_name], :created_at => Date.today)
    ChecklistLocation.first_or_create(:location_id => params[:loc2_id], :type => params[:loc2_type], :response_id => @response.id, :name => params[:loc2_name], :created_at => Date.today)


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

        section.dropdownpoints.each do |drop_down|
          if params["drop_down_point_#{drop_down.id}".to_sym].to_i==0
            raise Exception
          end
        end

        #if the control comes here....the validations have passed.

        #save all the yes/no questions
        section.checkpoints.each do |checkpoint|

          if !params["checkpoint_#{checkpoint.id}".to_sym].blank?
          @checkpoint_filling= checkpoint.checkpoint_fillings.create!(:status => params["checkpoint_#{checkpoint.id}".to_sym], :response_id => @response.id)
            end

        end
        #save all the free texts
        section.free_texts.each do |free_text|
          if !params["free_text_#{free_text.id}".to_sym].blank?
          @free_text_filling=free_text.free_text_fillings.create!(:comment => params["free_text_#{free_text.id}".to_sym], :response_id => @response.id)
            end
        end

        #save all drop downs

        section.dropdownpoints.each do |drop_down|

          @dropdownpoint_filling=drop_down.dropdownpoint_fillings.create!(:model_record_id => params["drop_down_point_#{drop_down.id}".to_sym].to_i, :response_id => @response.id,:model_record_name=>Kernel.const_get(drop_down.model_name).get(params["drop_down_point_#{drop_down.id}".to_sym].to_i).name)
        end

        #save all checkbox points
        section.checkboxpoints.each do |checkbox_point|
          checkbox_point.checkboxpoint_options.each do |option|
            if !params["option#{option.id}".to_sym].blank?
            @checkboxpoint_option_filling=option.checkboxpoint_option_fillings.create!(:status => params["option#{option.id}".to_sym].to_i, :response_id => @response.id)
              end
          end
        end


      end

    rescue Exception => e
     # message={:error => e.message}
      message={:error => params[:result_status]}
      #message[:error]="Fields cannot be blank"
       render :fill_in_checklist, :message => message
      redirect url(:checklister_slice_fill_in_checklist, @checklist, params), :message => message

    else


      redirect url(:checklister_slice_checklists, parameter_hash)
    end


    #@sample=params
    #display @sample


  end


end # Checklists
