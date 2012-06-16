class UserManager
  include Constants::User

  attr_reader :created_at
  
  def initialize; @created_at = DateTime.now; end

  def get_user(for_user_id)
    user = User.get(for_user_id)
    raise Errors::DataError, "Unable to locate user with ID: #{for_user_id}" unless user
    user
  end

  def get_user_for_login(login)
    user = User.first(:login => login)
    raise Errors::DataError, "Unable to locate user with login: #{login}" unless user
    user
  end

  def get_first_user
    User.first
  end

  def get_operator
    all_users = User.all
    operator = nil
    all_users.each { |user|
      operator = user if user.get_user_role == OPERATOR
      break if operator
    }
    operator
  end
 
end
