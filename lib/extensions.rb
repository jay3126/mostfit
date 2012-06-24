module Misfit
  module Extensions
    module User
      CUD_Actions =["create", "new", "edit", "update", "destroy", "approve", "disburse", "reject", "suggest_write_off", "write_off_suggest", "write_off", "write_off_reject", "bulk_new", "bulk_create", "bulk_create_loan_applicant"]
      CR_Actions =["create", "new", "index", "show", "list"]
      #add hooks to before and after can_access? and can_manage? methods to override their behaviour
      # here we add hooks to see if the user can manage a particular instance of a model.
      def self.included(base)
        Merb.logger.info "Included Misfit::Extensions::User by #{base}"
        base.class_eval do
          alias :can_access? :_can_access?
          #congratulations you have over-ridden the base methods
          # you can now pollute away
        end
      end

      def additional_checks
        id = @route[:id].to_i
        model = Kernel.const_get(@model.to_s.split("/")[-1].camelcase)
        if model == StaffMember
          #Trying to check his own profile? Allowed!
          return(true) if @staff.id==id
          st = StaffMember.get(id)
          # Allow access to this staff member if it is his branch manager
          # do not allow a staff member any other staff member access
          return false if @staff.branches.length==0 and @staff.areas.length==0 and @staff.regions.length==0 
          # Only allow branch managers to edit or create a new staff member
          return is_manager_of?(st.centers.branches)
        elsif model == Branch
          branch = Branch.get(id)
          if [:delete].include?(@action.to_sym)
            return (@staff.areas.length>0 or @staff.regions.length>0)
          elsif @action.to_sym==:edit
            return is_manager_of?(branch)
          else
            return(is_manager_of?(branch) or branch.centers.manager.include?(@staff))
          end
        elsif [Comment, Document, InsurancePolicy, InsuranceCompany, Cgt, Grt, AuditTrail].include?(model)
          reutrn true
        elsif model.respond_to?(:get)
          return is_manager_of?(model.get(id))
        else
          return false
        end
      end

      def is_funder?
        allowed_controller = (access_rights[:all].include?(@controller.to_sym))
        return false unless allowed_controller
        id = @route[:id].to_i
        model = Kernel.const_get(@model.to_s.split("/")[-1].camelcase)
        if [Branch, Center, ClientGroup, Client, Loan, StaffMember, FundingLine, Funder, Portfolio].include?(model) and id>0 
          return(@funder.send(model.to_s.snake_case.pluralize, {:id => id}).length>0)
        elsif [Branch, Center, ClientGroup, Client, Loan, StaffMember, FundingLine, Funder, Portfolio].include?(model) and id==0
          return(@funder.send(model.to_s.snake_case.downcase.pluralize).length>0)
        elsif [Browse, Document, AuditTrail, Attendance, Search, Bookmark].include?(model)
          return true
        end
        return false
     end

      def is_manager_of?(obj)
        @staff ||= self.staff_member
        return false unless obj
        return true if [:admin, :mis_manager].include?(self.role)
        return false if [:funder, :read_only, :accountant, :maintainer].include?(self.role)
        return true if self.role == :data_entry and not @staff # data entry member who does not have a staff role means he does data entry across all branches / regions
        if obj.class == Region
          return(obj.manager == @staff ? true : false)
        elsif obj.class == Area
          return(obj.manager == @staff or is_manager_of?(obj.region))
        elsif obj.class == Branch
          return(obj.manager == @staff or is_manager_of?(obj.area))
        elsif obj.class == Center
          return(obj.manager == @staff or is_manager_of?(obj.branch))
        elsif obj.class == Client
          return(is_manager_of?(obj.center))
        elsif obj.class == ClientGroup
          return(obj.center.manager == @staff or is_manager_of?(obj.center))
        elsif obj.is_a?(Loan)
          return(is_manager_of?(obj.client.center))
        elsif obj.is_a?(Payment)
          return(is_manager_of?(obj.loan))
        elsif obj.class == StaffMember
          return true if obj == @staff 
          #branch manager needs access to the its Center managers
          return(is_manager_of?(obj.centers)) if @staff.branches.count > 0
          #area manager needs access to the its branch managers and center managers
          return(is_manager_of?(obj.branches) or is_manager_of?(obj.centers)) if @staff.areas.count > 0
          #region manager needs access to the its area manager, branch managers and center managers
          return(is_manager_of?(obj.areas) or is_manager_of?(obj.branches) or is_manager_of?(obj.centers)) if @staff.regions.count > 0
          return false
        elsif obj.respond_to?(:map)
          return(obj.map{|x| is_manager_of?(x)}.uniq.include?(true))
        else
          return false
        end
      end
      
      def rights_from_access_rules
        if access_rights.key?(@action.to_s.to_sym) and access_rights[@action.to_s.to_sym].include?(@controller.to_sym)
          return true
        elsif r = access_rights[:all]
          r.include?(@controller.to_sym) || r.include?(@controller.split("/")[0].to_sym)
        end
      end
      
      def allow_read_only
        return false if CUD_Actions.include?(@action)
        return true if @controller=="admin" and @action=="index"
        return rights_from_access_rules
      end

      def _can_access?(route, params = nil)
        user_role = self.get_user_role
        return true if user_role == :administrator

        @route = route
        @params = params
        @controller = (route[:namespace] ? route[:namespace] + "/" : "" ) + route[:controller]
        @model = route[:controller].singularize.to_sym
        @action = route[:action]

        if user_role == :supervisor
          return true if [:loan_applications].include?(@model)
          return true unless [:edit, :update, :delete, :destroy, :bulk_create, :bulk_new].include?(@action.to_sym)
          return false
        end
      end
    end#User

    def self.hook
      # includes the modules in their respective classes
      self.constants.each do |mod|
        object = Kernel.const_get(mod.to_s)
        object.class_eval do
          Merb.logger.info("Hooking extensions for #{mod}")
          include module_eval("Misfit::Extensions::#{mod}")
        end
      end
    end
  end
end
