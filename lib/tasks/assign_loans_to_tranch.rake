=begin

arguments:
file_name:       string for the file name. Assume that the file will be placed under public/uploads. If a file with the name does not exist, raise an error and exit

Structure of the rake task:

1) Read all arguments
  a) Assignment type and assignment name
  # If the securitisation or encumberance of the given name does not exist, raise and error and exit
  b) Test for file with the file name at the expected location
  # If the file is not found, raise an error and exit

2) Read the file and collect all the Loan IDs, Funder Id and Effective On dates supplied
  # If an error occurs while reading the file and the Loan IDs, raise an error and exit
  # If the file was read successfully, create a data structure and another file to write out the results of processing the file

3) Process the list of pairs of loan IDs, Funder Id, Effective On dates, one at a time, and write out the results and errors. Write to the file as each loan is processed
  # For each loan, invoke the FundsSource model's right method and try to assign the loan to that tranch for that Effective Date
  # Record the success or error in the data structure against each loan

=end

require 'colored'

namespace :mostfit do
  namespace :loan_assignment do

    desc "Assign loans to a tranch."
    task :assign_loans_to_tranch, :file_name do |t, args|
      require 'fastercsv'

      USAGE_TEXT = <<USAGE_TEXT
USAGE:

rake mostfit:loan_assignment:assign_loans_to_tranch[<'file_name'>]

Upload the file which contains list of loan IDs in public/upload directory and this rake task
The results will be written to a .csv in public/uploads directory
with status of loan assignment as success or failure (with a failure error message)
USAGE_TEXT

      file_path = File.join(Merb.root, 'public', 'uploads')
      LOAN_ID = "Loan ID"
      FUNDS_ID = "Funds ID"
      EFFECTIVE_ON = "Effective On"
      
      begin
        errors = []

        file_name = args[:file_name]
        raise ArgumentError, "Loan file name must not be blank" unless (file_name and not(file_name.empty?))

        fq_file_path = File.join(file_path, file_name)
        raise ArgumentError, "File name: #{file_name} not found in #{file_path}" unless File.exists?(fq_file_path)
        
        file_to_write = File.join(file_path, file_name + ".results.csv")
        file_options = {:headers => true}

        loans_data = {} #this will be a hash of hashes where information against each loan will be stored.
        FasterCSV.foreach(fq_file_path, file_options) do |row|
          puts "Processing #{row} \n".green
          loan_id_str = row[LOAN_ID]
          funds_id_str = row[FUNDS_ID]
          effective_on_str = row[EFFECTIVE_ON]

          puts loan_id_str.blue
          puts funds_id_str.blue
          puts effective_on_str.blue

          loan_id = loan_id_str.to_i
          effective_on_date = Date.strptime(effective_on_str,'%d-%m-%Y')
          funds_id = funds_id_str.to_i
          
          puts "#{loan_id}".green
          puts "#{funds_id}".green
          puts "#{effective_on_date}".green
          loans_data[loan_id] = {
              :effective_on => effective_on_str,
              :funds_id => funds_id_str,
          }
        end

        FasterCSV.open(file_to_write, "w"){ |fastercsv|
          fastercsv << [ 'Loan ID', 'Funds ID', 'Effective On','Status', 'Error' ]
          loans_data.each {|loan_id|
            loan_status, loan_error = "Not known", "Not known"
            begin
              FundsSource.assign_to_tranch_on_date(loan_id, loans_data[loan_id][FUNDS_ID], loans_data[loan_id][EFFECTIVE_ON])
              loan_status, loan_error = "Success", ''
            rescue => ex
              loan_status, loan_error = 'Failure', ex.message
            end
            fastercsv << [loan_id, loans_data[loan_id][FUNDS_ID], loans_data[loan_id][EFFECTIVE_ON], loan_status, loan_error]
          }
        }

      rescue => ex
        puts "Error message: #{ex.message}\n".red
        puts USAGE_TEXT.blue
      end

    end
  end
end
