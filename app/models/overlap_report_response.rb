class OverlapReportResponse
  include DataMapper::Resource
  
  property :id,                  Serial
  property :created_at,          DateTime
  property :created_by_staff_id, Integer
  property :total_outstanding,   Integer
  property :no_of_active_loans,  Integer
  property :total_outstanding,   Integer
  property :loan_application_id, Integer
  property :not_matched,         Boolean, :nullable => :false

  

end
