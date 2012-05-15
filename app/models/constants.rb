module Constants

  module Center

    CENTER_CATEGORIES = ['','urban','rural']

  end

  module Client

    RELIGIONS = ['Hindu','Muslim','Sikh','Christian','Jain','Buddha']
    CASTES = ['General','SC','ST','OBC']
  end

  # points in space
  module Space

    REGION = :region; AREA = :area; BRANCH = :branch; CENTER = :center

    LOCATIONS = [REGION, AREA, BRANCH, CENTER]
    LOCATION_IMMEDIATE_ANCESTOR = { CENTER => BRANCH, BRANCH => AREA, AREA => REGION }
    LOCATION_IMMEDIATE_DESCENDANT = { REGION => AREA, AREA => BRANCH, BRANCH => CENTER }
    MODELS_AND_LOCATIONS = { "Region" => REGION, "Area" => AREA, "Branch" => BRANCH, "Center" => CENTER }
    LOCATIONS_AND_MODELS = { REGION => 'Region', AREA => 'Area', BRANCH => 'Branch', CENTER => 'Center' }

    PROPOSED_MEETING_STATUS = 'proposed'; CONFIRMED_MEETING_STATUS = 'confirmed'; RESCHEDULED_MEETING_STATUS = 'rescheduled'
    MEETING_SCHEDULE_STATUSES = [PROPOSED_MEETING_STATUS, CONFIRMED_MEETING_STATUS, RESCHEDULED_MEETING_STATUS]

    MEETINGS_SUPPORTED_AT = [ CENTER ]

    def self.all_ancestors_for_type(location_type)
      ancestors = []
      anc = LOCATION_IMMEDIATE_ANCESTOR[location_type]
      while (not (anc.nil?))
        ancestors << anc
        anc = LOCATION_IMMEDIATE_ANCESTOR[anc]
      end
      ancestors
    end

    def self.all_descendants_for_type(location_type)
      descendants = []
      descend = LOCATION_IMMEDIATE_DESCENDANT[location_type]
      while (not (descend.nil?))
        descendants << descend
        descend = LOCATION_IMMEDIATE_DESCENDANT[descend]
      end
      descendants
    end

    # resolves the instance to a constant symbol using the class name
    def self.to_location_type(location_obj)
      MODELS_AND_LOCATIONS[location_obj.class.name]
    end

    def self.to_klass(location_type)
      klass_name = LOCATIONS_AND_MODELS[location_type]
      klass_name ? Kernel.const_get(klass_name) : nil
    end

    def self.ancestor_type(location)
      LOCATION_IMMEDIATE_ANCESTOR[to_location_type(location)]
    end

    def self.all_ancestors(location)
      all_ancestors_for_type(to_location_type(location))
    end

    def self.descendant_type(location)
      LOCATION_IMMEDIATE_DESCENDANT[to_location_type(location)]
    end

    def self.descendant_association(location)
      descendant_type_name = descendant_type(location)
      descendant_type_name.nil? ? nil : descendant_type_name.to_s.pluralize
    end

    def self.all_descendants(location)
      all_descendants_for_type(to_location_type(location))
    end

  end

  module Status

    LOAN_APPLIED_STATUS = :loan_applied; LOAN_APPROVED_STATUS = :loan_approved
    LOAN_STATUSES = [LOAN_APPLIED_STATUS, LOAN_APPROVED_STATUS]

  end

end