class FacadeFactory
  include Singleton

  # Use this factory to obtain instances of any facade

  attr :created_at

  MEETING_FACADE = :meeting
  LOAN_FACADE = :loan
  LOCATION_FACADE = :location
  PAYMENT_FACADE = :payment
  FACADE_TYPES = { MEETING_FACADE => MeetingFacade, LOAN_FACADE => LoanFacade, LOCATION_FACADE => LocationFacade, PAYMENT_FACADE => PaymentFacade }

  def initialize
    @created_at = DateTime.now
  end

  # Factory that locates and returns instances of the requested facade that is_a
  # StandardFacade
  def get_instance(of_facade_type, for_user, with_options = {})
    facade_klass = FACADE_TYPES[of_facade_type]
    raise ArgumentError, "No facade configured for requested facade type: #{of_facade_type}" unless facade_klass
    facade_klass.new(for_user, with_options)
  end

  # Factory that returns an instance of a facade to be invoked from another facade
  def get_other_facade(of_facade_type, given_facade, with_options = {})
    for_user = given_facade.for_user
    get_instance(of_facade_type, for_user, with_options)
  end

end
