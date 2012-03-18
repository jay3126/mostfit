module Constants
  # All constants for use in the application should be namespaces under further modules under this module

  module Status
    #All constants that are related to statuses, handle with care

    CREATED_STATUS = :created; SENT_STATUS = :sent
    REQUEST_STATUSES = [CREATED_STATUS, SENT_STATUS, :response_received]

    NEW_STATUS = :new; APPROVED_STATUS = :approved
    APPLICATION_STATUSES = [NEW_STATUS, :pending_overlap_report, :overlap_report_cleared, :overlap_report_rejected, APPROVED_STATUS, :rejected, :on_hold]

    LOAN_OUTSTANDING_STATUS = :outstanding
    LOAN_STATUSES = [LOAN_OUTSTANDING_STATUS]

  end

  module Space

    OPEN_CENTER_CYCLE_STATUS = 'open_center_cycle_status'; CLOSED_CENTER_CYCLE_STATUS = 'closed_center_cycle_status'
    CENTER_CYCLE_STATUSES = [ OPEN_CENTER_CYCLE_STATUS, CLOSED_CENTER_CYCLE_STATUS ]
    
  end

  module Masters
    REFERENCE_TYPES = ["Passport", "Voter ID", "UID", "Others", "Ration Card", "Driving Licence No", "Pan"]
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

end
