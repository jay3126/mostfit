class LendingProductLocation
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,                Serial
  property :effective_on,      *DATE_NOT_NULL
  property :performed_by,      *INTEGER_NOT_NULL
  property :recorded_by,       *INTEGER_NOT_NULL
  property :created_at,        *CREATED_AT
  property :updated_at,        *UPDATED_AT
  property :deleted_at,        *DELETED_AT

  belongs_to :biz_location
  belongs_to :lending_product

end
