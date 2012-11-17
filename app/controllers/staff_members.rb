class StaffMembers < Application
  include DateParser
  layout :determine_layout
  provides :xml

  def index
    @date = params[:date] ? parse_date(params[:date]) : Date.today
    @staff_members = @staff_members ? @staff_members : StaffMember.all
    display @staff_members
  end

  #serves info tab for staff member
  def moreinfo(id)
    @render_form = true
    @render_form = false if params[:_target_]
    @from_date   = params[:from_date] ? parse_date(params[:from_date]) : Date.min_date
    @to_date     = params[:to_date]   ? parse_date(params[:to_date])   : Date.today
    allow_nil    = (params[:from_date] or params[:to_date]) ? false : true
    @staff_member= StaffMember.get(id)
    raise NotFound unless @staff_member

    if allow_nil
      @clients       = @center.clients(:fields => [:id])
    else
      @clients       = @center.clients(:fields => [:id], :date_joined.lte => @to_date, :date_joined.gte => @from_date)
    end

    @groups_count  = @center.client_groups(:fields => [:id]).count
    @clients_count = @clients.count
    @payments      = Payment.collected_for(@center, @from_date, @to_date)
    @fees          = Fee.collected_for(@center, @from_date, @to_date)
    @loan_disbursed= LoanHistory.amount_disbursed_for(@center, @from_date, @to_date)
    @loan_data     = LoanHistory.sum_outstanding_for(@center, @to_date)
    @defaulted     = LoanHistory.defaulted_loan_info_for(@center, @to_date)
    render :file => 'branches/moreinfo', :layout => false
  end

  def show_branches(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @branches = @staff_member.branches
    display @branches
  end

  def show_centers(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @centers = @staff_member.centers
    display @centers
  end

  def show_clients(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @clients = @staff_member.centers.clients
    display @clients
  end

  def show_disbursed(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @loans = @staff_member.disbursed_loans
    display @loans
  end

  def day_sheet(id)
    @weeksheets       = []
    @staff_member     = StaffMember.get(id)
    @date             = params[:date] ? parse_date(params[:date]) : get_effective_date
    @date             = @date.holiday_bump
    @biz_location_ids = params[:biz_location_ids]
    @message          = {}
    @message[:error]  = 'Please Select Location For Repayment' if(@biz_location_ids.blank? && params[:payment]==true)
    if @biz_location_ids.blank?
      @weeksheets = collections_facade.get_collection_sheet_for_staff(@staff_member.id, @date)
    else
      @biz_location_ids.each{|location_id| @weeksheets << CollectionsFacade.new(session.user.id).get_collection_sheet(location_id, @date)}
    end
    if params[:format] == "pdf"
      file = @staff_member.generate_collection_pdf(session.user.id, @date)
      filename   = File.join(Merb.root, "doc", "pdfs", "staff", @staff_member.name, "collection_sheets", "collection_#{@staff_member.id}_#{@date.strftime('%Y_%m_%d')}.pdf")
      if file
        send_data(File.read(filename), :filename => filename, :type => "application/pdf")
      else
        redirect resource(@staff_member), :message => {:notice => "No centers for collection today"}
      end
    else
      display @weeksheets, :message => @message
    end
  end

  def disbursement_sheet(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    @date = params[:date] ? parse_date(params[:date]): Date.today
    @date = @date.holiday_bump
    center_ids = LoanHistory.all(:date => [@date, @date.holidays_shifted_today].uniq, :fields => [:loan_id, :date, :center_id], :status => [:approved]).map{|x| x.center_id}.uniq
    @centers   = @staff_member.centers(:id => center_ids).sort_by{|x| x.name}
    if params[:format] == "pdf"
      file = @staff_member.generate_disbursement_pdf(@date)
      filename   = File.join(Merb.root, "doc", "pdfs", "staff", @staff_member.name, "disbursement_sheets", "disbursement_#{@staff_member.id}_#{@date.strftime('%Y_%m_%d')}.pdf")
      if file
        send_data(File.read(filename), :filename => filename, :type => "application/pdf")
      else
        redirect resource(@staff_member), :message => {:notice => "No centers for collection today"}
      end
    else
      display @centers
    end
  end
  
  def show(id)
    @staff_member = StaffMember.get(id)
    @date = params[:date] ? Date.parse(params[:date]) : get_effective_date
    @option = params[:option]
    raise NotFound unless @staff_member
    @manage_locations = LocationManagement.locations_managed_by_staff(@staff_member.id, get_effective_date)
    @staff_members = StaffMember.all - [@staff_member]
    display @staff_member
  end

  def new
    only_provides :html
    @staff_member = StaffMember.new
    display @staff_member
  end

  def edit(id)
    only_provides :html
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    display @staff_member
  end

  def create(staff_member)
    @message = {:notice => [], :error => []}
    recorded_by = session.user.id
    performed_by = session.user.staff_member
    biz_location_id = params[:biz_location_id]
    manage_location_ids = params[:manage_location_ids]||[]
    manage_locations = manage_location_ids.blank? ? [] : BizLocation.all(:id => manage_location_ids)
    @staff_member = StaffMember.new(staff_member)
    
    begin
      manage_locations.each do |location|
        assigned = LocationManagement.first(:managed_location_id => location.id, :effective_on => @staff_member.creation_date)
        @message[:error] << "There is already a staff member(#{assigned.manager_staff_member.name.humanize}) assigned to manage the location on the date: #{assigned.effective_on}" unless assigned.blank?
      end
      if @message[:error].blank?
        if @staff_member.save
          StaffPosting.assign(@staff_member, BizLocation.get(biz_location_id), @staff_member.creation_date, performed_by.id, recorded_by.id) unless biz_location_id.blank?
          manage_locations = manage_location_ids.blank? ? [] : BizLocation.all(:id => manage_location_ids)
          manage_locations.each do |location|
            LocationManagement.assign_manager_to_location(@staff_member, location, @staff_member.creation_date, performed_by.id, recorded_by.id)
          end
          @message[:notice] = "StaffMember '#{@staff_member.name}' (Id:#{@staff_member.id}) was successfully created"
        else
          @message[:error] = @staff_member.errors.first.join('<br>')
        end
      end
    rescue => ex
      @message[:error] << "An error has occured: #{ex.message}"
    end

    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)

    if @message[:error].blank?
      redirect resource(:staff_members), :message => @message
    else
      render :new
    end
  end

  def update(id, staff_member)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    if @staff_member.update_attributes(staff_member)
      redirect resource(@staff_member), :message => {:notice => "Details of staff member '#{@staff_member.name}' (Id: #{@staff_member.id}) was successfully updated"}
    else
      display @staff_member, :edit
    end
  end

  def destroy(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    if @staff_member.destroy
      redirect resource(:staff_members)
    else
      raise InternalServerError
    end
  end
  
  def display_sheets(id)
    @staff_member = StaffMember.get(id)
    raise NotFound unless @staff_member
    date =  (Date.strptime(params[:date], Mfi.first.date_format)).strftime('%Y_%m_%d')   
    type = params[:type_sheet]
    @folder = File.join(Merb.root, "doc", "pdfs", "staff", @staff_member.name, type)
    @files = Dir.entries(@folder).select{|f| f.match(/.*#{date}.*pdf$/)} if File.exists?(@folder)
    display @files, :layout => false
  end

  def send_sheet(filename)
    send_data(File.read(filename), :filename => filename, :type => "application/pdf")
  end

  # this redirects to the proper url, used from the router
  def redirect_to_show(id)
    raise NotFound unless @staff_member = StaffMember.get(id)
    redirect resource(@staff_member)
  end

  def assign_location_to_staff
    #INITIALIZING VALIABLE USED THROUGHTOUT

    @message = {}

    #GATE-KEEPING

    staff_id     = params[:id]
    location_id  = params[:staff_member][:managed_location_id]
    effective_on = params[:staff_member][:effective_on]
    recorded_by  = session.user.id
    perfomed_by  = params[:staff_member][:perfomed_by]
    @staff       = StaffMember.get staff_id

    #VALIDATION

    @message = {:error => "Please select location"} if location_id.blank?
    @message = {:error => "Please select Perfomed by"} if perfomed_by.blank?
    @message = {:error => "Effective Date cannot blank"} if effective_on.blank?

    #OPERATION

    if @message[:error].blank?
      begin
        biz_location    = BizLocation.get location_id
        assign_location = LocationManagement.assign_manager_to_location(@staff, biz_location, effective_on, perfomed_by, recorded_by)
        if assign_location.new?
          @message = {:notice => "Staff assignment fail"}
        else
          @message = {:notice => "Staff has assign to location seccussfully"}
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(@staff), :message => @message
  end

  def fetch_staff_member_locations
    @colName = ["id", 'effective_on']
    @colCount = params[:iColumns]
    order = @colName[params[:iSortCol_0].to_i].blank? ? @colName.first : [@colName[params[:iSortCol_0].to_i]]
    limit = params[:iDisplayLength].to_i <= 0 ? 10 : params[:iDisplayLength].to_i

    @all_location_manages = LocationManagement.locations_managed_by_staff(params[:id].to_i, get_effective_date)
    @iTotalRecords = @all_location_manages.size
    if params[:sSearch].blank?
      @location_manages = LocationManagement.all(:order => order, :id => @all_location_manages.map(&:id), :limit => limit, :offset => params[:iDisplayStart].to_i)
      @iTotalDisplayRecords = @iTotalRecords
    else
      @iTotalDisplayRecords = (LocationManagement.all(:order => order, :id => @all_location_manages.map(&:id))&(
          LocationManagement.all(:managed_location_id.like => params[:sSearch])|
          LocationManagement.all('staff_member.name'.to_sym.like => '%'+params[:sSearch]+'%')|
          LocationManagement.all('biz_location.location_level.name'.to_sym.like => '%'+params[:sSearch]+'%')|
          LocationManagement.all('biz_location.name'.to_sym.like => '%'+params[:sSearch]+'%')|
          LocationManagement.all(:effective_on => '%'+params[:sSearch]+'%'))).count
      @location_manages = LocationManagement.all(:order => order, :id => @all_location_manages.map(&:id))&(
        LocationManagement.all(:managed_location_id.like => params[:sSearch], :limit => limit, :offset => params[:iDisplayStart].to_i)|
        LocationManagement.all('staff_member.name'.to_sym.like => '%'+params[:sSearch]+'%', :limit => limit, :offset => params[:iDisplayStart].to_i)|
        LocationManagement.all('biz_location.location_level.name'.to_sym.like => '%'+params[:sSearch]+'%', :limit => limit, :offset => params[:iDisplayStart].to_i)|
        LocationManagement.all('biz_location.name'.to_sym.like => '%'+params[:sSearch]+'%', :limit => limit, :offset => params[:iDisplayStart].to_i)|
        LocationManagement.all(:effective_on => '%'+params[:sSearch]+'%', :limit => limit, :offset => params[:iDisplayStart].to_i))
    end
    @sEcho = params[:sEcho].to_i
    display @location_manages, :layout => layout?
  end

  private
  def determine_layout
    return "printer" if params[:layout] and params[:layout]=="printer"
  end
  
end # StaffMembers
