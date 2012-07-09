# To change this template, choose Tools | Templates
# and open the template in the editor.

module CommonClient
  module Validations

    LOAN_APPLICATION_MAPPING  = {
      :client_name => :name,
      :client_address => :address,
      :client_pincode => :pincode,
      :client_reference1 => :reference,
      :client_reference1_type => :reference_type,
      :client_reference2 => :reference2,
      :client_reference2_type => :reference2_type,
      :client_guarantor_name => :guarantor_name,
      :client_guarantor_relationship => :guarantor_relationship
    }

    CLIENT_MAPPING = {
      :name => :name,
      :address => :address,
      :pincode => :pincode,
      :reference => :reference,
      :reference_type => :reference_type,
      :reference2 => :reference2,
      :reference2_type => :reference2_type,
      :guarantor_name => :guarantor_name,
      :guarantor_relationship => :guarantor_relationship
    }

    VALIDATIONS = {
      :name => {:nullable => false, :length => 100},
      :address => {:nullable => false},
      :pincode => {:nullable => false, :max => AddressValidation::PIN_CODE_MAX_INT_VALUE},
      :reference => {:nullable => false, :length => 100, :format => Constants::ReferenceFormatValidations::FORMAT_REFERENCE1},
      :reference_type => {:default => Constants::Masters::DEFAULT_REFERENCE_TYPE},
      :reference2 => {:nullable => false, :format => Constants::ReferenceFormatValidations::FORMAT_REFERENCE2},
      :reference2_type => {:default => Constants::Masters::DEFAULT_REFERENCE2_TYPE},
      :guarantor_name => {:nullable => false},
      :guarantor_relationship => {:default => Constants::Masters::OTHER_RELATIONSHIP}
    }

    CLASSES_AND_MAPPINGS = { LoanApplication => LOAN_APPLICATION_MAPPING, Client => CLIENT_MAPPING }

    def self.get_validation(for_property, for_klass)
      raise ArgumentError, "There is no mapping for class: #{for_klass}" unless CLASSES_AND_MAPPINGS.keys.include?(for_klass)
      klass_mapping = CLASSES_AND_MAPPINGS[for_klass]
      klass_property_name = klass_mapping[for_property]
      raise ArgumentError, "There is no mapping for the property: #{for_property}" unless klass_property_name
      VALIDATIONS[klass_property_name]
    end

  end
end
