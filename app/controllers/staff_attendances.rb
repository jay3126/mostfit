class StaffAttendances < Application

  def index

  end

  def new

  end

  def create
    # INITIALIZATION
    @errors = []
    @message = {}

    # GATE-KEEPING
    on_date         = params[:on_date]
    attendance_ids  = params[:was_attendance_ids]
    location_id     = params[:biz_location_id]
    total_staff_ids = params[:staff_ids]
    performed_by_id = session.user.staff_member.id
    recorded_by_id  = session.user.id
    attendance_ids  = attendance_ids.blank? ? [] : attendance_ids

    #VALIDATIONS
    @errors << "Location cannot be blank" if location_id.blank?

    # OPERATION PERFORMED
    if @errors.blank?
      begin
        staff_members = total_staff_ids.collect{|c| StaffMember.get c}
        staff_attendances = StaffAttendance.get_all_recorded_attendance_status_at_location(location_id, on_date).map(&:staff_member_id)
        staff_members.each do |staff|
          status = attendance_ids.include?(staff.id.to_s)
          if staff_attendances.include?(staff.id)
            StaffAttendance.update_attendance(staff.id, status, on_date, location_id.to_i, performed_by_id, recorded_by_id)
          else
            StaffAttendance.record_attendance(staff.id, status, on_date, location_id.to_i, performed_by_id, recorded_by_id)
          end
        end
        @message = {:notice => "Staff Attendance save successfully"}
      rescue => ex
        @message = {:error => ex.message}
      end
    else
      @message = {:error => @errors.to_a.flatten.join(', ')}
    end

    #REDIRECT/RENDER
    redirect url(:controller => :user_locations, :action => :show, :id => location_id), :message => @message

  end

  def edit

  end

  def update

  end
end