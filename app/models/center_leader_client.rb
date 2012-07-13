class CenterLeaderClient
  include DataMapper::Resource
  include Constants::Properties

  property :id,                 Serial
  property :client_id,          Integer,  :nullable => false
  property :biz_location_id,    Integer,  :nullable => false
  property :date_assigned,      Date,     :nullable => false
  property :is_center_leader,   Boolean,  :nullable => true, :default => false
  property :created_at,         *CREATED_AT

  def self.set_center_leader(client_id, at_location_id, on_effective_date)
    delete_existing_center_leader(at_location_id, on_effective_date)
    center_leader_hash = {}
    center_leader_hash[:client_id] = client_id
    center_leader_hash[:biz_location_id] = at_location_id
    center_leader_hash[:date_assigned] = on_effective_date
    center_leader_hash[:is_center_leader] = true
    center_leader = create(center_leader_hash)
    raise Errors::DataError, center_leader.errors.first.first unless center_leader.saved?
  end


  def self.is_center_leader?(client_id, on_effective_date)
    center_leader = first(:client_id => client_id, :date_assigned => on_effective_date)
    return true if center_leader
    return false
  end

  def self.delete_existing_center_leader(at_location_id, on_effective_date)
    existing_center_leader = all(:biz_location_id => at_location_id, :date_assigned => on_effective_date)
     unless existing_center_leader.blank?
       existing_center_leader.each do |center_leader|
         center_leader.destroy
       end
     end
  end
end
