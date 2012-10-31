class LoanAssignments < Application

  require "tempfile"

  def loan_assignment
    @loan_assignments = get_all_loan_assignments
    render
  end

  def upload_loan_assignment_file
    # INITIALIZATIONS
    @errors = []
    @total_records = 0
    @sucessfully_uploaded_records = 0
    @failed_records = 0
    applied_by_staff = recorded_by_user = get_session_user_id
    securitization = Constants::LoanAssignment::SECURITISED
    encumbrance = Constants::LoanAssignment::ENCUMBERED

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
        FileUtils.rm_rf("#{csv_folder}/.")
        csv_filepath = File.join(csv_folder, filename)

        User.convert_xls_to_csv(xls_filepath, csv_filepath)
        converted_csv_file = Dir.entries(csv_folder).select{|d| d.split('.').include?('csv')}.to_s
        fq_file_path = File.join(csv_folder, converted_csv_file)
        output_folder = File.join("#{Merb.root}/public/uploads/loan_assignments", "results")
        FileUtils.mkdir_p(output_folder)
        file_to_write = File.join(output_folder, "loan_assignments" + ".results.csv")
        file_options = {:headers => true}

        loans_data = {}
        row_no = 1
        FasterCSV.foreach(fq_file_path, file_options) do |row|
          row_no             += 1
          loan_id_str        = row["Loan ID"]
          effective_on_str   = row["Effective on"]
          funder_id          = row["Funder ID"]
          funding_line_id    = row["Funding line ID"]
          tranch_id          = row["Tranch ID"]
          assignment_type    = row["Assignment type"]
          loan_id = loan_id_str.to_i
          effective_on_date = effective_on_str.blank? ? '' : Date.parse(effective_on_str)
          loans_data[row_no] = {
            :loan_id            => loan_id,
            :effective_on_date  => effective_on_date,
            :funder_id          => funder_id,
            :funding_line_id    => funding_line_id,
            :tranch_id          => tranch_id,
            :assignment_type    => assignment_type,
          }
        end

        @total_records = CSV.readlines(fq_file_path).size - 1
        FasterCSV.open(file_to_write, "w") do |fastercsv|
          fastercsv << [ 'Loan ID', 'Effective On', 'Funder ID', 'Funding line ID', 'Tranch ID', 'Assignment type', 'Assignment type ID', 'Status', 'Error' ]
          record_no = 0
          if CSV.readlines(fq_file_path).size <= 1
            raise "File must not be blank"
          else
            loans_data.each do |row_id, data|
              msg = []
              record_no += 1
              loan_status, loan_error = "Not known", "Not known"
              id                 = data[:loan_id]
              effective_on_date  = data[:effective_on_date]
              funder_id          = data[:funder_id]
              funding_line_id    = data[:funding_line_id]
              tranch_id          = data[:tranch_id]
              assignment_type    = data[:assignment_type]
              loan_assignment = loan_assignment_facade.get_loan_assigned_to(id, Date.today)

              # VALIDATIONS
              is_loan_eligible, reason = (Lending.get(id).blank?) ? [false, "Loan ID not valid"] : loan_facade.is_loan_eligible_for_loan_assignments?(id)
              if reason.blank?
                msg << "Effective on date must not be blank" if effective_on_date.blank?

                funder = NewFunder.get funder_id
                msg << "Funder ID not found" if funder.blank?

                funding_line = NewFundingLine.get funding_line_id
                msg << "Funding Line ID not found" if funding_line.blank?

                tranch = NewTranch.get tranch_id
                msg << "Tranch ID not found" if tranch.blank?

                msg << "Assignment type must not be blank" if assignment_type.blank?

                unless funder.blank? || funding_line.blank? || tranch.blank?
                  msg << "No relation with exists between Funder ID - Funding Line ID - Tranch ID" if tranch.new_funding_line.id != funding_line.id || funding_line.new_funder.id != funder.id
                end
                unless assignment_type.blank?
                  if (assignment_type != "s" && assignment_type != "e" && assignment_type != "ae")
                    msg << "Assignment type: #{assignment_type} is not defined.(Use 's' for Securitization and 'e' for Encumbrance and 'ae' for Additional Encumbrance)"
                  else
                    if (loan_assignment && loan_assignment.is_additional_encumbered) || (is_default_tranch_set? && get_default_tranch_id == tranch_id.to_i)
                      if assignment_type == "s"
                        assignment_nature = securitization
                      else
                        assignment_nature = encumbrance
                      end
                    else
                      if (assignment_type == "s" && tranch.assignment_type == "securitization")
                        assignment_nature = securitization
                      elsif (assignment_type == "e" && tranch.assignment_type == "encumbrance") || (assignment_type == "ae")
                        assignment_nature = encumbrance
                      else
                        msg << "Tranch ID: #{tranch.id} can only be used for #{tranch.assignment_type}"
                      end
                    end
                    if assignment_nature == :securitised
                      msg << "Ineligible Loan for assignment: (Loan does not have minimum #{get_no_of_minimum_repayments} repayments)" unless (Lending.get(id).loan_receipts.size >= get_no_of_minimum_repayments)
                    end
                  end
                end
              else
                msg << reason
              end
            
              begin
                if msg.blank?
                  additional_encumbered = assignment_type == "ae" ? true : false
                  loan_assignment_facade.assign_on_date(id, assignment_nature, effective_on_date, funder_id, funding_line_id, tranch_id, additional_encumbered)
                  loan_facade.assign_tranch_to_loan(id, funding_line_id, tranch_id, applied_by_staff, effective_on_date, recorded_by_user)
                  @sucessfully_uploaded_records += 1
                  loan_status, loan_error = "Success", ''
                end
                unless msg.blank?
                  @failed_records += 1
                  @errors << "Row No. #{row_id}, Loan ID #{id}: #{msg.flatten.join(', ')}"
                end
              rescue => ex
                @failed_records += 1
                @errors << "Row No. #{row_id}, Loan ID #{id}: #{ex.message}, #{msg.flatten.join(', ')}"
                loan_status, loan_error = 'Failure', "#{ex.message}, #{msg.flatten.join(', ')}"
              end
              fastercsv << [id, effective_on_date, funder_id, funding_line_id, tranch_id, assignment_type, loan_status, loan_error]
            end
          end
        end
      rescue => ex
        @errors << ex.message
      end
    end
    @loan_assignments = get_all_loan_assignments
    render :loan_assignment
  end

  def download_xls_file_format
    send_file('public/loan_assignment_file_format.xls', :filename => ('public/loan_assignment_file_format.xls'.split("/")[-1].chomp))
  end

  private

  def get_all_loan_assignments
    loan_assignments = []
    all_loan_assignments = LoanAssignment.all
    aggregated_ids = all_loan_assignments.aggregate(:loan_id)
    aggregated_ids.each do |loan_id|
      loan_assignments << LoanAssignment.all(:loan_id => loan_id).last
    end
    loan_assignments
  end

end