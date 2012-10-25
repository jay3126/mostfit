class AccountingLocation
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction, Constants::Accounting

  property :id,                Serial
  property :effective_on,      *DATE_NOT_NULL
  property :product_type,      Enum.send('[]', *PRODUCT_LOCATION), :nullable => false
  property :product_id,        *INTEGER_NOT_NULL
  property :performed_by,      *INTEGER_NOT_NULL
  property :recorded_by,       *INTEGER_NOT_NULL
  property :created_at,        *CREATED_AT
  property :updated_at,        *UPDATED_AT
  property :deleted_at,        *DELETED_AT

  belongs_to :biz_location, :nullable => true
  belongs_to :cost_center, :nullable => true

  def product; Resolver.fetch_model_instance(self.product_type.humanize, self.product_id); end

end
