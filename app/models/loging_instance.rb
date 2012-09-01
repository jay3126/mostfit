class LoginInstance
  include DataMapper::Resource
  include Constants::Properties
  include Constants::User
  include Identified

  property :id,           Serial
  property :login_time,   DateTime, :nullable => false
  property :logout_time,  DateTime, :nullable => true
  property :created_at,   DateTime              
  property :updated_at,   DateTime

  belongs_to :user

end
