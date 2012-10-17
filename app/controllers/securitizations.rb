class Securitizations < Application

  require "tempfile"

  def index
    @securitizations=Securitization.all
    display @securitizations
  end
  
  def show
    @securitization = Securitization.get(params[:id])
    raise NotFound unless @securitization
    @date = params[:secu_date].blank? ? get_effective_date : Date.parse(params[:secu_date])
    @lendings = loan_assignment_facade.get_loans_assigned(@securitization,@date) 

    do_calculations

    render :template => 'securitizations/show', :layout => layout?
  end

  def new
    @securitization=Securitization.new
    display @securitization
  end
  
  def create(securitization)
    @securitization = Securitization.new(securitization)
    @errors = []
    @errors << "Securitization name must not be blank " if params[:securitization][:name].blank?
    @errors << "Effective date must not be blank " if params[:securitization][:effective_on].blank?
    if @errors.blank?
      if(Securitization.all(:name => @securitization.name).count==0)
        if @securitization.save!
          redirect("/securitizations", :message => {:notice => "Securitization '#{@securitization.name}' (Id:#{@securitization.id}) successfully created"})
        else
          message[:error] = "Securitization failed to be created"
          render :new  # error messages will show
        end
      else
        message[:error] = "Securitization with same name already exists !"
        render :new  # error messages will show
      end
    else
      message[:error] = @errors.to_s
      render :new
    end
  end

  def loans_for_securitization_on_date
    @securitization = Securitization.get(params[:id])
    raise NotFound unless @securitization
    @date = params[:secu_date].blank? ? get_effective_date : Date.parse(params[:secu_date])
    @lendings = loan_assignment_facade.get_loans_assigned(@securitization,@date) 

    do_calculations

    render :template => 'securitizations/show', :layout => layout?
  end

  def do_calculations
    @errors = []
    money_hash_list = []
    begin 
      @lendings.each do |lending|
        lds = LoanDueStatus.most_recent_status_record_on_date(lending, @date)
        money_hash_list << lds.to_money
      end 
        
      in_currency = MoneyManager.get_default_currency
      @total_money = Money.add_money_hash_values(in_currency, *money_hash_list)
    rescue => ex
      @errors << ex.message
    end
  end

  def eligible_loans_for_loan_assignments
    @errors = []
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    unless params[:flag] == 'true'
      @errors << "No branch selected " if branch_id.blank?
      @errors << "No center selected " if center_id.blank?
    end
    @lendings = loan_facade.loans_eligible_for_sec_or_encum(params[:child_location_id]) if @errors.blank?
    render :eligible_loans_for_loan_assignments
  end

  def loan_assignments
    @loan_assignments = LoanAssignment.all
    render
  end

  def upload_loan_assignment_file
    # INITIALIZATIONS
    @errors = []
    @loan_assignments = LoanAssignment.all
    @total_records = 0
    @sucessfully_uploaded_records = 0
    @failed_records = 0
    applied_by_staff = recorded_by_user = get_session_user_id
    applied_on_date = get_effective_date

    # VALIDATIONS
    @errors << "Please select file" if params[:file].blank?
    @errors << "Invalid file selection (Accepts .xls extension file only)" if params[:file][:content_type] && params[:file][:content_type] != "application/vnd.ms-excel"

    # OPERATION PERFORMED
    if @errors.blank?
      begin
        filename = params[:file][:filename]
        xls_folder = File.join("#{Merb.root}/public/uploads", "loan_assignments", "uploaded_xls")
        FileUtils.mkdir_p(xls_folder)
        xls_filepath = File.join(xls_folder, filename)
        FileUtils.mv(params[:file][:tempfile].path, xls_filepath)

        csv_folder = File.join("#{Merb.root}/public/uploads", "loan_assignments", "converted_csv")
        FileUtils.mkdir_p(csv_folder)
        csv_filepath = File.join(csv_folder, "loan_assignment")

        User.convert_xls_to_csv(xls_filepath, csv_filepath)

        fq_file_path = "#{csv_filepath}.csv.0"
        output_folder = File.join("#{Merb.root}/public/uploads/loan_assignments", "results")
        FileUtils.mkdir_p(output_folder)
        file_to_write = File.join(output_folder, "loan_assignments" + ".results.csv")
        file_options = {:headers => true}

        loans_data = {}
        FasterCSV.foreach(fq_file_path, file_options) do |row|
          loan_id_str        = row["Loan ID"]
          effective_on_str   = row["Effective on"]
          funder_id          = row["Funder ID"]
          funding_line_id    = row["Funding line ID"]
          tranch_id          = row["Tranch ID"]
          assignment_type    = row["Assignment type"]
          assignment_type_id = row["Assignment type ID"]
          loan_id = loan_id_str.to_i
          effective_on_date = effective_on_str.blank? ? '' : Date.parse(effective_on_str)
          loans_data[loan_id] = {
            :effective_on_date  => effective_on_date,
            :funder_id          => funder_id,
            :funding_line_id    => funding_line_id,
            :tranch_id          => tranch_id,
            :assignment_type    => assignment_type,
            :assignment_type_id => assignment_type_id
          }
        end

        @total_records = loans_data.keys.size
        FasterCSV.open(file_to_write, "w") do |fastercsv|
          fastercsv << [ 'Loan ID', 'Effective On', 'Funder ID', 'Funding line ID', 'Tranch ID', 'Assignment type', 'Assignment type ID', 'Status', 'Error' ]
          record_no = 0
          loans_data.each do |id, data|
            msg = []
            record_no += 1
            loan_status, loan_error = "Not known", "Not known"
            effective_on_date  = data[:effective_on_date]
            funder_id          = data[:funder_id]
            funding_line_id    = data[:funding_line_id]
            tranch_id          = data[:tranch_id]
            assignment_type    = data[:assignment_type]
            assignment_type_id = data[:assignment_type_id]

            # VALIDATIONS
            msg << "Effective on date must not be blank" if effective_on_date.blank?

            funder = NewFunder.get funder_id
            msg << "Funder ID not found" if funder.blank?

            funding_line = NewFundingLine.get funding_line_id
            msg << "Funding Line ID not found" if funding_line.blank?

            tranch = NewTranch.get tranch_id
            msg << "Tranch ID not found" if tranch.blank?

            msg << "Assignment type must not be blank" if assignment_type.blank?

            msg << "Assignment type id must not be blank" if assignment_type_id.blank?
              
            begin
              unless funder.blank? || funding_line.blank? || tranch.blank?
                msg << "No relation with exists between Funder ID - Funding Line ID - Tranch ID" if tranch.new_funding_line.id != funding_line.id || funding_line.new_funder.id != funder.id
              end

              unless assignment_type.blank? || assignment_type_id.blank?
                msg << "Assignment type: #{assignment_type} is not defined.(Use 's' for Securitization and 'e' for Encumbrance)" if (assignment_type != "s" && assignment_type != "e")

                if assignment_type == "s"
                  assignment_type_object = Securitization.get assignment_type_id
                  msg << "No Securitization found with Id #{assignment_type_id}" if assignment_type_object.blank?
                else
                  assignment_type_object = Encumberance.get assignment_type_id
                  msg << "No Encumbrance found with Id #{assignment_type_id}" if assignment_type_object.blank?
                end
              end

              if msg.blank?
                loan_assignment_facade.assign_on_date(id, assignment_type_object, data[:effective_on_date], funder_id, funding_line_id, tranch_id)
                loan_facade.assign_tranch_to_loan(id, funding_line_id, tranch_id, applied_by_staff, applied_on_date, recorded_by_user)
                @sucessfully_uploaded_records += 1
                loan_status, loan_error = "Success", ''
              end
              unless msg.blank?
                @failed_records += 1
                @errors << "Loan IsD #{id}: #{msg.flatten.join(', ')}"
              end
            rescue => ex
              @failed_records += 1
              @errors << "Loan ID #{id}: #{ex.message}, #{msg.flatten.join(', ')}"
              loan_status, loan_error = 'Failure', "#{ex.message}, #{msg.flatten.join(', ')}"
            end
            fastercsv << [id, effective_on_date, funder_id, funding_line_id, tranch_id, assignment_type, assignment_type_id, loan_status, loan_error]
          end
        end

      rescue => ex
        @errors << ex.message
      end
    end

    render :loan_assignments
  end

  def download_xls_file_format
    send_file('public/loan_assignment_file_format.xls', :filename => ('public/loan_assignment_file_format.xls'.split("/")[-1].chomp))
  end

end