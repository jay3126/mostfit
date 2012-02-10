class Centers < Application
  before :get_context, :exclude => ['redirect_to_show', 'groups']
  before :get_date,    :only    => ['show', 'weeksheet']
  provides :xml, :yaml, :js

  def index    
    redirect resource(@branch) if @branch
    hash = {:order => [:meeting_day, :meeting_time_hours]}
    hash[:manager] = session.user.staff_member if session.user.role == :staff_member
    hash[:branch] = @branch if @branch
    @centers = Center.all(hash).paginate(:per_page => 15, :page => params[:page] || 1)
    display @centers
  end

  def list
    @centers = @centers ? @centers.all(:meeting_day => params[:meeting_day]||Date.today) : @branch.centers_with_paginate({:meeting_day => params[:meeting_day]}, session.user)
    partial "centers/list", :layout => layout?
  end

  def show(id)
    @option = params[:option] if params[:option]
    @center = Center.get(id)
    raise NotFound unless @center
    @branch  =  @center.branch if not @branch
    @clients =  grouped_clients
    @all_clients   = (LoanHistory.all(:center_id => @center.id).clients + @clients).uniq
    @moved_clients = @all_clients - @clients
    @moved_loans   = LoanHistory.all(:center_id => @center.id).loans   - @center.clients.loans

    if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
      display [@center, @clients, @date]
    else
      display [@center, @clients, @date], 'clients/index'
    end
  end

  def today(id)
    @center = Center.get(id)
    raise NotFound unless @center
    @clients = @center.clients
    @loans = @clients.loans
    display [@center, @clients, @loans], 'clients/today'
  end

  def bulk_data_entry(id)
    only_provides :html
    @center = Center.get(id)
    raise NotFound unless @center
    @clients = @center.clients
    raise NotFound unless params[:field_name]
    match, model_name, field = /(\w+)\[(\w+)\]/.match(params[:field_name]).to_a
    return unless model_name and field
    @model            = Kernel.const_get(model_name.camelcase) 
    @field            = field.to_sym
    raise NotAllowed unless (MASS_ENTRY_FIELDS[model_name.to_sym] and MASS_ENTRY_FIELDS[model_name.to_sym].include?(@field))
    @field            = :occupation if @model == Loan and @field==:purpose
    if request.method==:get
      render :layout => layout?
    elsif request.method==:post
      model = Kernel.const_get(params["model"])
      column = if property = model.properties.find{|x| x.name == @field}
                 property.name
               elsif model.relationships[@field]
                 model.relationships[@field].child_key.first.name
               end
      raise NotAllowed unless column
      saved = []
      params[params["model"].snake_case].each{|id, attr|
        if id and not id.blank? and attr.length>0
          attr.each{|col, val|
            next if val.blank?
            val = val.to_i if /^\d+$/.match(val)
            obj = model.get(id)     
            next if obj.send(column) == val
            obj.history_disabled=true if model==Loan
            obj.send("#{column}=", val)
            saved << obj.save_self
          }
        end
      }
      saved = saved.uniq
      if saved == [true]
        return("<div class='notice'>Saved successfully</div>")
      elsif saved.include?(true) and saved.include?(false)
        return("<div class='notice'>Saved with some errors</div>")
      else
        return("<div class='error'>Sorry! Not able to save</div>")
      end
    end
  end



  def bulk_move
    if request.method == :get
      @errors = {}
      @branch = Branch.get(params[:branch_id])
      raise NotFound unless @branch
      @centers = @branch.centers
      render
    else
      debugger
      @branch = Branch.get(params[:branch_id])
      raise NotFound unless @branch
      @date = Date.parse(params[:date]) rescue nil
      @new_branch = Branch.get(params[:new_branch_id])
      if @date and @new_branch
        Center.transaction do |t|
          Center.all(:id => params[:centers].keys.map(&:to_i)).each do |c|
            c.move_to_branch(@new_branch, @date)
          end
        end
      end
      redirect resource(@new_branch), :message => {:success => "All centers moved succesfully and loans updated"}
    end
  end
  

  def new
    only_provides :html
    @center = Center.new
    display @center
  end

  def create(center)
    @center_meeting_day = CenterMeetingDay.new(center.delete(:center_meeting_day))
    @center_meeting_day.valid_from = center[:creation_date]
    @center_meeting_day.valid_upto = Date.new(2100,12,31)
    @center = Center.new(center)
    @center.center_meeting_days << @center_meeting_day
    if @branch
      @center.branch = @branch  # set direct context
    end
    if @center.save
      debugger
      @center_meeting_day.center_id = @center.id
      @center_meeting_day.save
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @center
      else
        redirect(params[:return]||resource(@center), :message => {:notice => "Center '#{@center.name}' (Id:#{@center.id}) successfully created"})
      end
    else
      #       message[:error] = "Center failed to be created"
      if params[:format] and API_SUPPORT_FORMAT.include?(params[:format])
        display @center
      else
        render :new  # error messages will be shown
      end
    end
  end

  def edit(id)
    only_provides :html
    @center = Center.get(id)
    raise NotFound unless @center
    display @center
  end

  def update(id, center)
    @center = Center.get(id)
    raise NotFound unless @center
    @center.attributes = center

    if @center.save
      redirect(params[:return]||resource(@center), :message => {:notice => "Center '#{@center.name}' (Id:#{@center.id}) has been successfully edited"})
    else
      display @center, :edit  # error messages will be shown
    end
  end

  def delete(id)
    edit(id)  # so far these are the same
  end

  def destroy(id)
    @center_meeting_day = CenterMeetingDay.new(center.delete(:center_meeting_day))
    @center_meeting_day.valid_from = center[:creation_date]
    @center_meeting_day.valid_upto = Date.new(2100,12,31)
    @center = Center.get(id)
    raise NotFound unless @center
    if @center.destroy
      redirect resource(@branch, :centers), :message => {:notice => "Center '#{@center.name}' (Id:#{@center.id}) has been deleted successfully"}
    else
      raise InternalServerError
    end
  end

  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @center = Center.get(id)
    redirect resource(@center.branch, @center)
  end

  def surprise_center_visits
    @center = Center.get(params[:id])
    raise NotFound unless @center 
    @surprise_center_visits = @center.surprise_center_visits
    partial "centers/surprise_center_visits"
  end

  def client_groups
    if params[:id]
      center = Center.get(params[:id])
      next unless center
      return("<option value=''>Select client group</option>"+center.client_groups(:order => [:name]).map{|br| "<option value=#{br.id}>#{br.name}</option>"}.join)
    end 
  end

  def groups
    only_provides :json
    if params[:group_id]
      group  = ClientGroup.get(params[:group_id])
      center = Center.get(params[:id])
      branch = center.branch
      render "{code: '#{branch.code.strip if branch and branch.code}#{center.code.strip if center and center.code}#{group.code.strip if group and group.code}'}"
    else
      @groups = Center.get(params[:id]).client_groups
      display @groups
    end
  end

  def weeksheet
    @clients_grouped = grouped_clients
    @clients = @center.clients
    partial "centers/weeksheet"
  end
  
  def misc
    @center =  Center.get(params[:id])
    raise NotFound unless @center
    @meeting_days  =  @center.center_meeting_days(:order => [:valid_from])
    partial "centers/misc"
  end

  private
  include DateParser  # for the parse_date method used somewhere here..

  # this works from proper urls
  def get_context
    @branch       = Branch.get(params[:branch_id])
    @staff_member = StaffMember.get(params[:staff_member_id])
    @center       = Center.get(params[:center_id]) if params[:center_id]
    # raise NotFound unless @branch
  end

  def get_date
    if params[:date]
      if params[:date].is_a? String
        @date = Date.parse(params[:date])
      elsif params[:date].is_a? Mash
        @date = parse_date(params[:date])
      end
    else
      @date = Date.today
    end
  end
  
  def grouped_clients
    clients = {}
    (@clients ? @clients.all(:center => @center) : @center.clients).each{|c|      
      group_name = c.client_group ? c.client_group.name : "No group"
      clients[group_name]||=[]
      clients[group_name] << c
    }
    clients.each{|k, v|
      clients[k]=v.sort_by{|c| c.name} if v
    }.sort.collect{|k, v| v}.flatten
  end
  
end # Centers
