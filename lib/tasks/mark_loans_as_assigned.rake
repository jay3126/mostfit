=begin

arguments:
assignment_type: securitization OR encumberance (create constants for these in LoanAssignment)
assignment_name: string which is the name for the securitization or encumberance. If the name is not matched exactly, raise an error, and exit
file_name:       string for the file name. Assume that the file will be placed under public/uploads. If a file with the name does not exist, raise an error and exit

Structure of the rake task:

1) Read all arguments
  a) Assignment type and assignment name
  # If the securitisation or encumberance of the given name does not exist, raise and error and exit
  b) Test for file with the file name at the expected location
  # If the file is not found, raise an error and exit

2) Read the file and collect all the Loan IDs, Effective On dates supplied
  # If an error occurs while reading the file and the Loan IDs, raise an error and exit
  # If the file was read successfully, create a data structure and another file to write out the results of processing the file

3) Process the list of pairs of loan IDs and Effective On dates, one at a time, and write out the results and errors. Write to the file as each loan is processed
  # For each loan, invoke the LoanAssignmentFacade and try to assign the loan for that Effective Date
  # Record the success or error in the data structure against each loan

=end

require 'colored'

namespace :mostfit do
  namespace :loan_assignment do

    desc "Mark loans for encumberance or for securitization."
    task :mark_loans, :assignment_type, :assignment_name, :file_name do |t, args|
      require 'fastercsv'

      USAGE_TEXT = <<USAGE_TEXT
USAGE:

rake mostfit:loan_assignment:mark_loans[<'assignment_type'>,<'assignment_name'>,<'file_name'>].

Assignment type should be either 'securitised' or 'encumbered'
Assignment name should be the name of the securitization (or encumberance)
Upload the file which contains list of loan IDs in public/upload directory and this rake task
The results will be written to a .csv in public/uploads directory
with status of loan assignment as success or failure (with a failure error message)
USAGE_TEXT

      SECURITIZATION = "securitization"
      ENCUMBERANCE = "encumberance"

      securitised_type = Constants::LoanAssignment::SECURITISED
      encumbered_type  = Constants::LoanAssignment::ENCUMBERED
      assignment_allowed_types = [securitised_type, encumbered_type]

      file_path = File.join(Merb.root, 'public', 'uploads')
      LOAN_ID = "Loan ID"
      EFFECTIVE_ON = "Effective On"
      
      begin
        errors = []

        assignment_type_str = args[:assignment_type]
        raise ArgumentError, "Loan Assignment type: #{assignment_type_str} is not valid" unless (assignment_type_str and not(assignment_type_str.empty?))
        assignment_type = assignment_type_str.to_sym
        raise ArgumentError, "Loan assignment type: #{assignment_type} is not recognized" unless assignment_allowed_types.include?(assignment_type)

        assignment_name = args[:assignment_name]
        raise ArgumentError, "Loan Assignment name must not be blank" unless (assignment_name and not(assignment_name.empty?))

        file_name = args[:file_name]
        raise ArgumentError, "Loan file name must not be blank" unless (file_name and not(file_name.empty?))

        fq_file_path = File.join(file_path, file_name)
        raise ArgumentError, "File name: #{file_name} not found in #{file_path}" unless File.exists?(fq_file_path)

        facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_ASSIGNMENT_FACADE, User.first)
        assignment_type_object = facade.find_assignment_by_type_and_name(assignment_type, assignment_name)
        raise ArgumentError, "Assignment name: #{assignment_name} by type #{assignment_type} was not found" if assignment_type_object.nil?

        file_to_write = File.join(file_path, file_name + ".results.csv")
        file_options = {:headers => true}

        loans_data = {}
        FasterCSV.foreach(fq_file_path, file_options) do |row|
          puts "Processing #{row} \n".green
          loan_id_str = row[LOAN_ID]
          effective_on_str = row[EFFECTIVE_ON]
          loan_id = loan_id_str.to_i
          effective_on_date = Date.strptime(effective_on_str,'%d-%m-%Y')
          loans_data[loan_id] = effective_on_date
        end

        FasterCSV.open(file_to_write, "w"){ |fastercsv|
          fastercsv << [ 'Loan ID', 'Effective On','Status', 'Error' ]
          loans_data.each {|id,date|
            loan_status, loan_error = "Not known", "Not known"
            begin
              facade.assign_on_date(id, assignment_type_object, date)
              loan_status, loan_error = "Success", ''
            rescue => ex
              loan_status, loan_error = 'Failure', ex.message
            end
            fastercsv << [id, date, loan_status, loan_error]
          }
        }

      rescue => ex
        puts "Error message: #{ex.message}\n".red
        puts USAGE_TEXT.blue
      end

    end
  end
end
