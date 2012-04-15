module Resolver

  def self.resolve_product(for_product)
    resolve_any(for_product, :products)
  end

  def self.resolve_location(for_location)
    resolve_any(for_location, :locations)
  end

  def self.resolve_client(for_client)
    resolve_any(for_client, :counter_parties)
  end

  MODEL_MAP = {
    :products => Constants::Products::MODELS_AND_PRODUCTS,
    :locations => Constants::Locations::MODELS_AND_LOCATIONS,
    :counter_parties => Constants::Clients::MODELS_AND_CLIENTS
  }
  
  private

  def self.resolve_any(obj, by_type)
    klass_name = obj.class.name
    type_string = MODEL_MAP[by_type][klass_name]
    raise ArgumentError, "no type resolved for #{obj}" unless type_string
    [type_string, obj.id]
  end

end