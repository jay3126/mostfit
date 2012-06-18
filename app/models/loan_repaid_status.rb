class LoanRepaidStatus
  include DataMapper::Resource
  include LoanLifeCycle, Constants::Properties

  property :id,            Serial
  property :repaid_nature, Enum.send('[]', *REPAID_NATURES), :nullable => false
  property :on_date,       *DATE_NOT_NULL
  property :created_at,    *CREATED_AT

  belongs_to :lending

end
