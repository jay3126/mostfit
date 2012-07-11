ROLE_MAPPER=Hash.new
ROLE_MAPPER["Surprise Center Visit"]={:performer =>"supervisor,operator", :viewer => "supervisor,read_only,operator"}
ROLE_MAPPER["Process Audit"]={:performer => "auditor,operator", :viewer => "auditor,read_only,operator"}
ROLE_MAPPER["Business Audit"]={:performer => "auditor,operator", :viewer => "auditor,read_only,operator"}
ROLE_MAPPER["Customer Calling"]={:performer => "telecaller,operator", :viewer => "telecaller,read_only,operator"}
ROLE_MAPPER["HealthCheck on Loan Files"]={:performer => "finops,operator", :viewer => "finops,read_only,operator"}