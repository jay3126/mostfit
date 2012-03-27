module Constants
  # All constants for use in the application should be namespaces under further modules under this module

  module CenterFormation

    GRT_NOT_DONE = 'grt_not_done'; GRT_PASSED = 'grt_passed'; GRT_FAILED = 'grt_failed'
    GRT_STATUSES = [GRT_NOT_DONE, GRT_PASSED, GRT_FAILED]
    GRT_COMPLETION_STATUSES = [GRT_PASSED, GRT_FAILED]
    
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

    APPLICATION_APPROVED = 'application_approved'; APPLICATION_REJECTED = 'application_rejected'
    APPLICATION_OVERRIDE_APPROVED = 'application_override_approved'; APPLICATION_OVERRIDE_REJECTED = 'application_override_rejected'
    APPLICATION_AUTHORIZATION_STATUSES = [
      APPLICATION_APPROVED, APPLICATION_REJECTED, APPLICATION_OVERRIDE_APPROVED, APPLICATION_OVERRIDE_REJECTED]

    APPLICATION_AUTHORIZATION_NOT_OVERRIDES = [APPLICATION_APPROVED, APPLICATION_REJECTED]
    APPLICATION_AUTHORIZATION_OVERRIDES = [APPLICATION_OVERRIDE_APPROVED, APPLICATION_OVERRIDE_REJECTED]

    REASON_FOR_NO_OVERRIDES = 'not_overriden'
    REASON_1 = 'reason_one'
    REASON_2 = 'reason_two'
    LOAN_AUTHORIZATION_OVERRIDE_REASONS = [REASON_FOR_NO_OVERRIDES, REASON_1, REASON_2]
  end

  module Space

    OPEN_CENTER_CYCLE_STATUS = 'open_center_cycle_status'; CLOSED_CENTER_CYCLE_STATUS = 'closed_center_cycle_status'
    CENTER_CYCLE_STATUSES = [ OPEN_CENTER_CYCLE_STATUS, CLOSED_CENTER_CYCLE_STATUS ]
    MINIMUM_CENTER_CYCLE_NUMBER = 1

  end

  module Masters
    REFERENCE_TYPES = ["Passport", "Voter ID", "UID", "Others", "Ration Card", "Driving Licence No", "Pan"]
    REFERENCE_TYPES_ID_PROOF = ["Passport", "Voter ID", "UID", "Others", "Driving Licence No", "Pan"]
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
