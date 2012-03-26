# A loan file lists a number of loan applications that are being processed together
class LoanFile
  include DataMapper::Resource
  
  property :id,                   Serial
  property :at_branch_id,         Integer, :nullable => false
  property :at_center_id,         Integer, :nullable => false
  property :for_cycle_number,     Integer, :nullable => false
  property :loan_file_identifier, String, :nullable => false,
    :default => lambda {|obj, p| "#{obj.at_branch_id}_#{obj.at_center_id}_#{obj.created_on.strftime('%d-%m-%Y')}"}
  property :created_by_staff_id,  Integer, :nullable => false
  property :created_on,           Date, :nullable => false
  property :created_by,           Integer, :nullable => false
  property :created_at,           DateTime, :nullable => false, :default => DateTime.now

  has n, :loan_applications

end
