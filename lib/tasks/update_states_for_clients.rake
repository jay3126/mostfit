#this rake task will update the states for all the clients in the system.
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')


namespace :mostfit do
  namespace :suryoday do
    desc "This rake task will update LAN for existing loans back to their original LAN of Suryoday"
    task :update_states_for_clients do
      client_ids = Client.all.aggregate(:id)

      client_ids.each do |cl|
        client = Client.get(cl)
        client_administration = ClientAdministration.first(:counterparty_type => :client, :counterparty_id => cl)
        branch = client_administration.registered_at
        biz_location = BizLocation.get(branch)
        state_location = biz_location.get_parent_location_at_location_level('state')
        state_name = state_location.blank? ? '' : state_location.name
        client.state = state_name
        client.save!
      end
    end
  end
end