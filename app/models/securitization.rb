class Securitization
  include DataMapper::Resource
  include Constants::Properties
  
  property :id,           Serial
  property :name,         String, :nullable => false, :length => 255,:unique=>true
  property :effective_on, *DATE_NOT_NULL
  property :created_at,   *CREATED_AT

  has n,:third_parties, :through => Resource

  def created_on; self.effective_on; end

  def to_s
    "<b>Securitization:</b> #{name} <b>Effective On:</b> #{effective_on}"
  end

  def self.mark_loans_as_assigned(file_path)
    begin
      loan_assignment_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_ASSIGNMENT_FACADE, User.first)
      fq_file_path = file_path
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
        effective_on_date = Date.parse(effective_on_str)
        loans_data[loan_id] = {
          :effective_on_date  => effective_on_date,
          :funder_id          => funder_id,
          :funding_line_id    => funding_line_id,
          :tranch_id          => tranch_id,
          :assignment_type    => assignment_type,
          :assignment_type_id => assignment_type_id
        }
      end

      FasterCSV.open(file_to_write, "w"){ |fastercsv|
        fastercsv << [ 'Loan ID', 'Effective On', 'Funder ID', 'Funding line ID', 'Tranch ID', 'Assignment type', 'Assignment type ID', 'Status', 'Error' ]
        loans_data.each do |id, data|
          begin
            loan_status, loan_error = "Not known", "Not known"
            effective_on_date  = data[:effective_on_date]
            funder_id          = data[:funder_id]
            funding_line_id    = data[:funding_line_id]
            tranch_id          = data[:tranch_id]
            assignment_type    = data[:assignment_type]
            assignment_type_id = data[:assignment_type_id]

            # VALIDATIONS
            funder = NewFunder.get funder_id
            raise "Funder ID not found" if funder.blank?
            funding_line = NewFundingLine.get funding_line_id
            raise "Funding Line ID not found" if funding_line.blank?
            tranch = NewTranch.get tranch_id
            raise "Tranch ID not found" if tranch.blank?

            raise "IDs Mismatch: No relation with given Funder, Funding Line and Tranch ID" if tranch.new_funding_line.id != funding_line.id || funding_line.new_funder.id != funder.id
            
            raise "Assignment type must not be blank" if assignment_type.blank?

            raise "Assignment type: #{assignment_type} is not defined.(Use 's' for Securitization and 'e' for Encumbrance)" if (assignment_type != "s" && assignment_type != "e")

            raise "Assignment type id must not be blank" if assignment_type_id.blank?
            
            if assignment_type == "s"
              assignment_type_object = Securitization.get assignment_type_id
              raise "No Securitization found with Id #{assignment_type_id}" if assignment_type_object.blank?
            else
              assignment_type_object = Encumberance.get assignment_type_id
              raise "No Encumbrance found with Id #{assignment_type_id}" if assignment_type_object.blank?
            end

            loan_assignment_facade.assign_on_date(id, assignment_type_object, data[:effective_on_date])
            loan_status, loan_error = "Success", ''
          rescue => ex
            loan_status, loan_error = 'Failure', ex.message
          end
          fastercsv << [id, data[:effective_on_date], data[:funder_id], data[:funding_line_id], data[:tranch_id], data[:assignment_type], data[:assignment_type_id], loan_status, loan_error]
        end
      }

    rescue => ex
      raise "Error message: #{ex.message}"
    end
  end

end