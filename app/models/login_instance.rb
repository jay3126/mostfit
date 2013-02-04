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
  property :login_date,   Date
  property :logout_date,  Date

  belongs_to :user

  def login_date_of_user
    login_date_user = (self.login_date and (not self.login_date.nil?)) ? self.login_date : "Not available at present"
    login_date_user
  end

  def login_time_of_user_formatted
    login_time_of_user = (self.login_time and (not self.login_time.nil?)) ? self.login_time.strftime("%I:%M %p") : "Not available at present"
    login_time_of_user
  end

  def logout_date_of_user
    logout_date_user = (self.logout_date and (not self.logout_date.nil?)) ? self.logout_date : "Logged in at present"
    logout_date_user
  end
  
  def logout_time_of_user_formatted
    logout_time_of_user = (self.logout_time and (not self.logout_time.nil?)) ? self.logout_time.strftime("%I:%M %p") : "Logged in at present"
    logout_time_of_user
  end

  def self.update_login_and_logout_date_for_existing_login_instances
    LoginInstance.all.each do |log|
      log.login_date = (log.login_time and (not log.login_time.nil?)) ? log.login_time.strftime("%d-%m-%Y") : nil
      log.logout_date = (log.logout_time and (not log.logout_time.nil?)) ? log.logout_time.strftime("%d-%m-%Y") : nil
      log.save!
    end
  end

end
