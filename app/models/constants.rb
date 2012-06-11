module Constants

  module Center

    CENTER_CATEGORIES = ['','urban','rural']

  end

  module Client

    RELIGIONS = ['Hindu','Muslim','Sikh','Christian','Jain','Buddha']
    CASTES = ['General','SC','ST','OBC']
  end

  module CenterFormation

    GRT_NOT_DONE = 'grt_not_done'; GRT_PASSED = 'grt_passed'; GRT_FAILED = 'grt_failed'
    GRT_STATUSES = [GRT_NOT_DONE, GRT_PASSED, GRT_FAILED]
    GRT_COMPLETION_STATUSES = [GRT_PASSED, GRT_FAILED]

  end

  module CreditBureau

    RATED_POSITIVE = 'positive'; RATED_NEGATIVE = 'negative'; NO_MATCH = 'no_match'

  end

  module Status
    #All constants that are related to statuses, handle with care

    CREATED_STATUS = :created; SENT_STATUS = :sent
    REQUEST_STATUSES = [CREATED_STATUS, SENT_STATUS, :response_received]

    NEW_STATUS = "new";
    SUSPECTED_DUPLICATE_STATUS = "suspected_duplicate"; NOT_DUPLICATE_STATUS = "not_duplicate"
    CONFIRMED_DUPLICATE_STATUS = "confirmed_duplicate"; CLEARED_NOT_DUPLICATE_STATUS = "cleared_not_duplicate"
    OVERLAP_REPORT_REQUEST_GENERATED_STATUS = "overlap_report_request_generated"; OVERLAP_REPORT_RESPONSE_MARKED_STATUS = "overlap_report_response_marked"
    AUTHORIZED_APPROVED_STATUS = "authorized_approved"; AUTHORIZED_REJECTED_STATUS = "authorized_rejected"
    AUTHORIZED_APPROVED_OVERRIDE_STATUS = "authorized_approved_override"; AUTHORIZED_REJECTED_OVERRIDE_STATUS = "authorized_rejected_override"
    CPV1_APPROVED_STATUS = "cpv1_approved"; CPV1_REJECTED_STATUS = "cpv1_rejected"; CPV2_APPROVED_STATUS = "cpv2_approved"; CPV2_REJECTED_STATUS = "cpv2_rejected"
    LOAN_FILE_GENERATED_STATUS = "loan_file_generated"

    CREATION_STATUSES = [NEW_STATUS]
    DEDUPE_STATUSES = [SUSPECTED_DUPLICATE_STATUS, NOT_DUPLICATE_STATUS, CONFIRMED_DUPLICATE_STATUS, CLEARED_NOT_DUPLICATE_STATUS]
    OVERLAP_REPORT_STATUSES = [OVERLAP_REPORT_REQUEST_GENERATED_STATUS, OVERLAP_REPORT_RESPONSE_MARKED_STATUS]
    AUTHORIZATION_STATUSES = [AUTHORIZED_APPROVED_STATUS, AUTHORIZED_APPROVED_OVERRIDE_STATUS, AUTHORIZED_REJECTED_STATUS, AUTHORIZED_REJECTED_OVERRIDE_STATUS]
    CPV_STATUSES = [CPV1_APPROVED_STATUS, CPV1_REJECTED_STATUS, CPV2_APPROVED_STATUS, CPV2_REJECTED_STATUS]
    LOAN_FILE_GENERATION_STATUSES = [LOAN_FILE_GENERATED_STATUS]

    LOAN_APPLICATION_STATUSES =
      (CREATION_STATUSES + DEDUPE_STATUSES + OVERLAP_REPORT_STATUSES + AUTHORIZATION_STATUSES + CPV_STATUSES + LOAN_FILE_GENERATION_STATUSES).flatten

    LOAN_OUTSTANDING_STATUS = :outstanding
    LOAN_STATUSES = [LOAN_OUTSTANDING_STATUS]

    APPLICATION_APPROVED = 'Approved'; APPLICATION_REJECTED = 'Rejected'
    APPLICATION_OVERRIDE_APPROVED = 'application_override_approved'; APPLICATION_OVERRIDE_REJECTED = 'application_override_rejected'
    APPLICATION_AUTHORIZATION_STATUSES = [
      APPLICATION_APPROVED, APPLICATION_REJECTED, APPLICATION_OVERRIDE_APPROVED, APPLICATION_OVERRIDE_REJECTED]

    APPLICATION_AUTHORIZATION_NOT_OVERRIDES = [APPLICATION_APPROVED, APPLICATION_REJECTED]
    APPLICATION_AUTHORIZATION_OVERRIDES = [APPLICATION_OVERRIDE_APPROVED, APPLICATION_OVERRIDE_REJECTED]

    REASON_FOR_NO_OVERRIDES = 'Not overriden'
    REASON_1 = 'Reason one'
    REASON_2 = 'Reason two'
    LOAN_AUTHORIZATION_OVERRIDE_REASONS = [REASON_FOR_NO_OVERRIDES, REASON_1, REASON_2]

    AUTHORIZATION_AND_APPLICATION_STATUSES = {
      APPLICATION_APPROVED => AUTHORIZED_APPROVED_STATUS, APPLICATION_OVERRIDE_APPROVED => AUTHORIZED_APPROVED_OVERRIDE_STATUS,
      APPLICATION_REJECTED => AUTHORIZED_REJECTED_STATUS, APPLICATION_OVERRIDE_REJECTED => AUTHORIZED_REJECTED_OVERRIDE_STATUS
    }

    HEALTH_CHECK_APPROVED = 'approved'
    HEALTH_CHECK_PENDING = 'pending'
    READY_FOR_DISBURSEMENT = 'ready_for_disbursement'
    HEALTH_CHECK_STATUSES = [ NEW_STATUS, HEALTH_CHECK_PENDING, HEALTH_CHECK_APPROVED, READY_FOR_DISBURSEMENT ]
    CREDIT_BUREAU_STATUSES = [CreditBureau::NO_MATCH, CreditBureau::RATED_POSITIVE, CreditBureau::RATED_NEGATIVE]

  end

  module Masters

    PASSPORT = :passport; VOTER_ID = :voter_id; UID = :uid; RATION_CARD = :ration_card; DRIVING_LICENCE = :driving_licence_no; PAN = :pan
    ALL_REFERENCE_TYPES = [PASSPORT, VOTER_ID, UID, RATION_CARD, DRIVING_LICENCE, PAN]
    REFERENCE_TYPES_ALLOWED = [RATION_CARD]
    REFERENCE2_TYPES_ALLOWED = ALL_REFERENCE_TYPES - REFERENCE_TYPES_ALLOWED

    DEFAULT_REFERENCE_TYPE = RATION_CARD
    DEFAULT_REFERENCE2_TYPE = VOTER_ID

    REFERENCE_TYPES = [PASSPORT, VOTER_ID, UID, RATION_CARD, DRIVING_LICENCE, PAN]
    RELATIONSHIPS = ["Father", "Husband", "Mother", "Son", "Daughter", "Wife", "Brother", "Mother-In-law", "Father-In-law", "Daughter-In-law", "Sister-In-Law", "Son-In-Law", "Brother-In-law", "Other"]
    LOAN_AMOUNTS = [10000, 12000, 15000]
    STATES = [
      "andhra_pradesh"     ,
      "arunachal_pradesh"  ,
      "assam"              ,
      "bihar"              ,
      "chattisgarh"        ,
      "goa"                ,
      "gujarat"            ,
      "haryana"            ,
      "himachal_pradesh"   ,
      "jammu_kashmir"      ,
      "jharkhand"          ,
      "karnataka"          ,
      "kerala"             ,
      "madhya_pradesh"     ,
      "maharashtra"        ,
      "manipur"            ,
      "meghalaya"          ,
      "mizoram"            ,
      "nagaland"           ,
      "orissa"             ,
      "punjab"             ,
      "rajasthan"          ,
      "sikkim"             ,
      "tamil_nadu"         ,
      "tripura"            ,
      "uttarakhand"        ,
      "uttar_pradesh"      ,
      "west_bengal"        ,
      "andaman_nicobar"    ,
      "chandigarh"         ,
      "dadra_nagar_haveli" ,
      "daman_diu"          ,
      "delhi"              ,
      "lakshadweep"        ,
      "pondicherry"
    ]
  end

  module Verification

    CPV1 = 'cpv1'; CPV2 = 'cpv2'
    CLIENT_VERIFICATION_TYPES = [CPV1, CPV2]

    NOT_VERIFIED = 'not_verified'; VERIFIED_ACCEPTED = 'verified_accepted'; VERIFIED_REJECTED = 'verified_rejected'
    CLIENT_VERIFICATION_STATUSES = [NOT_VERIFIED, VERIFIED_ACCEPTED, VERIFIED_REJECTED]

  end

  module MoneyDepositVerificationStatus

    PENDING_VERIFICATION = :pending_verification; VERIFIED_REJECTED = :verified_rejected; VERIFIED_CONFIRMED = :verified_confirmed
    MONEY_DEPOSIT_VERIFICATION_STATUSES = [ PENDING_VERIFICATION, VERIFIED_REJECTED, VERIFIED_CONFIRMED ]
    CHOOSE_VERIFICATION_STATUS = MONEY_DEPOSIT_VERIFICATION_STATUSES - [PENDING_VERIFICATION]
    
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

    OPEN_CENTER_CYCLE_STATUS = 'open_center_cycle_status'; CLOSED_CENTER_CYCLE_STATUS = 'closed_center_cycle_status'
    CENTER_CYCLE_STATUSES = [ OPEN_CENTER_CYCLE_STATUS, CLOSED_CENTER_CYCLE_STATUS ]
    
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



end