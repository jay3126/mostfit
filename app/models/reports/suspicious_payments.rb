class SuspiciousPayments < Report
	attr_accessor :branch_id

	#class method
	def self.name 
		"Suspicious Payments Reports"
	end

	#instance method
	def name
		"Suspicious Payments Reports"
	end

	def initialize(params,dates,user)
		@date = (dates and dates[:date]) ? dates[:date] : Date.today
    	@branch_id = (params and params.key?(:branch_id) and not (params[:branch_id] == "")) ? params[:branch_id] : 0
		get_parameters(params, user)  	
	end

	def generate(param)
        data = repository.adapter.query(%Q{
        select id, amount, c_branch_id, received_on, created_at, created_by_user_id, 
		if(deleted_at is not null,'Yes','No') as deleted, 
		deleted_at, deleted_by_user_id,datediff(received_on,created_at) as diff 
		from payments 
		where datediff(received_on,created_at) <> 0 
        and c_branch_id = #{@branch_id}
        })
    end
end
