class SimpleInsuranceProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Insurance

  property :id,            Serial
  property :name,          *UNIQUE_NAME
  property :insurance_for, Enum.send('[]', *INSURED_PERSON_RELATIONSHIPS)
  property :created_on,    *DATE_NOT_NULL
  property :created_at,    *CREATED_AT

  belongs_to :lending_product, :nullable => true
  has 1, :premium, 'SimpleFeeProduct'

end
