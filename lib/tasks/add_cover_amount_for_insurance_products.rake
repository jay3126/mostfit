#this rake task will add cover amounts for Simple Insurance Products.
#Add the local gems dir if found within the app root; any dependencies loaded
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
    desc "This rake task will add cover amount"
    task :add_cover_amount do

      #setting the default cover amount for all the insurance products.
      SimpleInsuranceProduct.all.each do |s|
        s.cover_amount = 0.0
        s.currency = :INR
        s.save!
      end

      #adding the cover amount of Rs.15,000.
      SimpleInsuranceProduct.all(:id => [2,4]).each do |sp|
        sp.cover_amount = 1500000
        sp.save
      end

      #adding the cover amount of Rs.20,000.
      SimpleInsuranceProduct.all(:id => [13,14,15]).each do |si|
        si.cover_amount = 2000000
        si.save
      end
    end
  end
end
