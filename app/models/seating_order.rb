class SeatingOrder
  include DataMapper::Resource
  include Constants::Properties

  GROUP_SIZE = 5

  property :id,                    Serial
  property :group_number,          *INTEGER_NOT_NULL
  property :position_within_group, *INTEGER_NOT_NULL
  property :absolute_position,     *INTEGER_NOT_NULL
  property :created_at,            *CREATED_AT

  belongs_to :biz_location
  belongs_to :client

  def self.assign_seating_order(list_of_clients, at_location_id)
    list_of_clients.each_with_index { |client_id, index|
      group_number = (index / GROUP_SIZE) + 1
      position_within_group = (index % GROUP_SIZE ) + 1
      seating_order = SeatingOrder.create(
        :group_number          => group_number,
        :position_within_group => position_within_group,
        :absolute_position     => (index + 1),
        :client_id             => client_id,
        :biz_location_id       => at_location_id
      )
    }
  end

  def self.get_complete_seating_order(at_location_id)
    all_seating_order_at_location = all(
      :biz_location_id => at_location_id,
      :order => [:absolute_position.asc]
    )
    all_seating_order_at_location.collect {|seating_order| seating_order.client_id}
  end

  def to_s
    "#{self.client.to_s} is at #{self.group_number}.#{self.position_within_group}"
  end

end