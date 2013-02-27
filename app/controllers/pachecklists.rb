class Pachecklists < Application
  # provides :xml, :yaml, :js

  def index
    @pachecklists = Pachecklist.all
     @biz_location = params[:biz_location]
     
    display @pachecklists
  end

  def show(id)
    @pachecklist = Pachecklist.get(id)
    @biz_location = BizLocation.get(@pachecklist.biz_location.id)
   
    raise NotFound unless @pachecklist
    display @pachecklist
  end

  def new
    only_provides :html
    @pachecklist2 = Pachecklist.new
    display @pachecklist
  end
  def answers
   only_provides :html
  # @biz_location_id = params[:biz_location_id]
   @biz_location_id = params[:biz_location_id]
   @biz_location = BizLocation.get(@biz_location_id)
   display @pachecklist
  end 
  def updateanswers

   @pachecklist_id = params[:pachecklist_id]
   @pachecklist = Pachecklist.get(@pachecklist_id)
   @biz_location_id = params[:biz_id]
   @q1 = params[:q1_1]
   @q2 = params[:q2_2]
   @q3 = params[:q3_3]
   @q4 = params[:q4_4]
   @q5 = params[:q5_5]
   @q6 = params[:q6_6]
   @q7 = params[:q7_7]
   @q8 = params[:q8_8]
   @q9 = params[:q9_9]
   @q10 = params[:q10_10]
   @q11 = params[:q11_11]
   @q12 = params[:q12_12]
   @q13 = params[:q13_13]
   @q14 = params[:q14_14]
   @q15 = params[:q15_15]
   @q16 = params[:q16_16]
   @q17 = params[:q17_17]
   @q18 = params[:q18_18]
   @q19 = params[:q19_19]
   @q20 = params[:q20_20]
   @q21 = params[:q21_21]
   @q22 = params[:q22_22]
   @q23 = params[:q23_23]
   @q24 = params[:q24_24]
   @q25 = params[:q25_25]
   @q26 = params[:q26_26]
   @q27 = params[:q27_27]
   @q28 = params[:q28_28]
   @q29 = params[:q29_29]
   @q30 = params[:q30_30]
   @q31 = params[:q31_31]
   @q32 = params[:q32_32]
   @q33 = params[:q33_33]
   @q34 = params[:q34_34]
   @q35 = params[:q35_35]
   @q36 = params[:q36_36]
   @q37 = params[:q37_37]
   @q38 = params[:q38_38]
   @q39 = params[:q39_39]
   @q40 = params[:q40_40]
   @q41 = params[:q41_41]
   @q42 = params[:q42_42]
   @q43 = params[:q43_43]
   @q44 = params[:q44_44]
   @q45 = params[:q45_45]
   @q46 = params[:q46_46]
   @q47 = params[:q47_47]
   @q48 = params[:q48_48]
   @q49 = params[:q49_49]
   @q50 = params[:q50_50]
   @q51 = params[:q51_51]
   @q52 = params[:q52_52]
   @q53 = params[:q53_53]
   
  @date_of_audit = params[:date_of_audit]
  @audit_period = params[:audit_period]
  
	@ans = Hash.new
	@ans[1] = @q1
	@ans[2] = @q2
	@ans[3] = @q3
	@ans[4] = @q4
	@ans[5] = @q5
	@ans[6] = @q6
	@ans[7] = @q7
	@ans[8] = @q8
	@ans[9] = @q9
	@ans[10] = @q10
	@ans[11] = @q11
	@ans[12] = @q12
	@ans[13] = @q13
	@ans[14] = @q14
	@ans[15] = @q15
	@ans[16] = @q16
	@ans[17] = @q17
	@ans[18] = @q18
	@ans[19] = @q19
	@ans[20] = @q20
	@ans[21] = @q21
	@ans[22] = @q22
	@ans[23] = @q23
	@ans[24] = @q24
	@ans[25] = @q25
	@ans[26] = @q26
	@ans[27] = @q27
	@ans[28] = @q28
	@ans[29] = @q29
	@ans[30] = @q30
	@ans[31] = @q31
	@ans[32] = @q32
	@ans[33] = @q33
	@ans[34] = @q34
	@ans[35] = @q35
	@ans[36] = @q36
	@ans[37] = @q37
	@ans[38] = @q38
	@ans[39] = @q39
	@ans[40] = @q40
	@ans[41] = @q41
	@ans[42] = @q42
	@ans[43] = @q43
	@ans[44] = @q44
	@ans[45] = @q45
	@ans[46] = @q46
	@ans[47] = @q47
	@ans[48] = @q48
	@ans[49] = @q49
	@ans[50] = @q50
	@ans[51] = @q51
	@ans[52] = @q52
	@ans[53] = @q53

   @scv_perday = params[:scv_perday]
   @meeting_attended_during_ap = params[:meeting_attended_during_ap]
   @branch_management = params[:branch_management]
   @social_audit = params[:social_audit]
   @supervision = params[:supervision]
   @positive1 = params[:positive1]
   @positive2 = params[:postive2]
   @positive3 = params[:positive3]
   @deviation1 = params[:deviation1]
   @deviation2 = params[:deviation2]
   @deviation3 = params[:deviation3]

   @text =  @ans.map {|k,vs| vs.map {|v| "#{k},#{v}"}}.join(",")
   @value_answers = Array.new
   @values_answers = @ans.values.to_a
   serialized_hash = Marshal.dump(@ans)
   @hash = Marshal.load(serialized_hash)
     @pachecklist.attributes = { :answers => @text }
     @pachecklist.attributes = { :date_of_audit => @date_of_audit }
     @pachecklist.attributes = { :audit_period => @audit_period }
     @pachecklist.attributes = { :scv_perday => @scv_perday }
     @pachecklist.attributes = { :meeting_attended_during_ap => @meeting_attended_during_ap }
     @pachecklist.attributes = { :branch_management => @branch_management }
     @pachecklist.attributes = { :social_audit => @social_audit }
     @pachecklist.attributes = { :supervision => @supervision }
     @pachecklist.attributes = { :positive1 => @positive1 }
     @pachecklist.attributes = { :postive2 => @positive2 }
     @pachecklist.attributes = { :positive3 => @positive3 }
     @pachecklist.attributes = { :deviation1 => @deviation1 }
     @pachecklist.attributes = { :deviation2 => @deviation2 }
     @pachecklist.attributes = { :deviation3 => @deviation3 }
     if @pachecklist.save
      redirect "/pachecklists?biz_location=#{@biz_location_id}", :message => {:notice => "process audit checklist was successfully created"}
     end  
      redirect "/pachecklists?biz_location=#{@biz_location_id}"
  end
  def allanswers
   only_provides :html
   #raise "yes you are now in answers action".inspect
   @biz_location_id = params[:biz_location_id]
   @q1 = params[:q1_1]
   @q2 = params[:q2_2]
   @q3 = params[:q3_3]
   @q4 = params[:q4_4]
   @q5 = params[:q5_5]
   @q6 = params[:q6_6]
   @q7 = params[:q7_7]
   @q8 = params[:q8_8]
   @q9 = params[:q9_9]
   @q10 = params[:q10_10]
   @q11 = params[:q11_11]
   @q12 = params[:q12_12]
   @q13 = params[:q13_13]
   @q14 = params[:q14_14]
   @q15 = params[:q15_15]
   @q16 = params[:q16_16]
   @q17 = params[:q17_17]
   @q18 = params[:q18_18]
   @q19 = params[:q19_19]
   @q20 = params[:q20_20]
   @q21 = params[:q21_21]
   @q22 = params[:q22_22]
   @q23 = params[:q23_23]
   @q24 = params[:q24_24]
   @q25 = params[:q25_25]
   @q26 = params[:q26_26]
   @q27 = params[:q27_27]
   @q28 = params[:q28_28]
   @q29 = params[:q29_29]
   @q30 = params[:q30_30]
   @q31 = params[:q31_31]
   @q32 = params[:q32_32]
   @q33 = params[:q33_33]
   @q34 = params[:q34_34]
   @q35 = params[:q35_35]
   @q36 = params[:q36_36]
   @q37 = params[:q37_37]
   @q38 = params[:q38_38]
   @q39 = params[:q39_39]
   @q40 = params[:q40_40]
   @q41 = params[:q41_41]
   @q42 = params[:q42_42]
   @q43 = params[:q43_43]
   @q44 = params[:q44_44]
   @q45 = params[:q45_45]
   @q46 = params[:q46_46]
   @q47 = params[:q47_47]
   @q48 = params[:q48_48]
   @q49 = params[:q49_49]
   @q50 = params[:q50_50]
   @q51 = params[:q51_51]
   @q52 = params[:q52_52]
   @q53 = params[:q53_53]
   @a1 = params[:a1]
   @a2 = params[:a2]
   @a3 = params[:a3]
   @a4 = params[:a4]
   @a5 = params[:a5]
   @a6 = params[:a6]
   @a7 = params[:a7]
   @a8 = params[:a8]
   @a9 = params[:a9]
   @b1 = params[:b1]
   @b2 = params[:b2]
   @b3 = params[:b3]
   @b4 = params[:b4]
   @b5 = params[:b5]
   @b6 = params[:b6]
   @b7 = params[:b7]
   @c1 = params[:c1]
   @c2 = params[:c2]   
   @c3 = params[:c3]
   @c4 = params[:c4]
   @c5 = params[:c5]
   @c6 = params[:c6]
   @c7 = params[:c7]

   
  @date_of_audit = params[:date_of_audit]
  @audit_period = params[:audit_period]
  @filled_by = session.user.staff_member_id
  @performed = StaffMember.get(@filled_by)
  @performed_by = @performed.name

  @cgt = Array.new
  @cgt.push(@a1,@a2,@a3,@a4,@a5,@a6,@a7,@a8,@a9,@b1,@b2,@b3,@b4,@b5,@b6,@b7,@c1,@c2,@c3,@c4,@c5,@c6,@c7)
  @cgt_i = 0
  @cgt.each do |cgt|
	   if cgt == "1"
	   @cgt_i+=1
	   end
        end

	@ans = Hash.new
	@ans[1] = @q1
	@ans[2] = @q2
	@ans[3] = @q3
	@ans[4] = @q4
	@ans[5] = @q5
	@ans[6] = @q6
	@ans[7] = @q7
	@ans[8] = @q8
	@ans[9] = @q9
	@ans[10] = @q10
	@ans[11] = @q11
	@ans[12] = @q12
	@ans[13] = @q13
	@ans[14] = @q14
	@ans[15] = @q15
	@ans[16] = @q16
	@ans[17] = @q17
	@ans[18] = @q18
	@ans[19] = @q19
	@ans[20] = @q20
	@ans[21] = @q21
	@ans[22] = @q22
	@ans[23] = @q23
	@ans[24] = @q24
	@ans[25] = @q25
	@ans[26] = @q26
	@ans[27] = @q27
	@ans[28] = @q28
	@ans[29] = @q29
	@ans[30] = @q30

        if @cgt_i == 23
  	 @ans[31] = "1"
        else 
  	 @ans[31] = "0"
        end
	@ans[32] = @q32
	@ans[33] = @q33
	@ans[34] = @q34
	@ans[35] = @q35
	@ans[36] = @q36
	@ans[37] = @q37
	@ans[38] = @q38
	@ans[39] = @q39
	@ans[40] = @q40
	@ans[41] = @q41
	@ans[42] = @q42
	@ans[43] = @q43
	@ans[44] = @q44
	@ans[45] = @q45
	@ans[46] = @q46
	@ans[47] = @q47
	@ans[48] = @q48
	@ans[49] = @q49
	@ans[50] = @q50
	@ans[51] = @q51
	@ans[52] = @q52
	@ans[53] = @q53
  
   @scv_perday = params[:scv_perday]
   if @scv_perday == "0" || @scv_perday == "6" || @scv_perday == "7"|| @scv_perday == "8"|| @scv_perday == "9"|| @scv_perday == "10" || @scv_perday == "" || @scv_perday == nil
       
   elsif @scv_perday.to_i > 0 || @scv_per_day.to_i < 6 || @scv_perday.to_i > 10
     redirect url(:answers_pachecklists, :biz_location_id => @biz_location_id), :message => {:notice => "process audit failed to save please enter  valid integer values to qualitative aspects  "}
   end
   @meeting_attended_during_ap = params[:meeting_attended_during_ap]
   @branch_management = params[:branch_management]
   @social_audit = params[:social_audit]
   @supervision = params[:supervision]
   @positive1 = params[:positive1]
   @positive2 = params[:postive2]
   @positive3 = params[:positive3]
   @deviation1 = params[:deviation1]
   @deviation2 = params[:deviation2]
   @deviation3 = params[:deviation3]
     


   @text =  @ans.map {|k,vs| vs.map {|v| "#{k},#{v}"}}.join(",")
   @name = Time.now.to_s
   @pachecklist = Pachecklist.new
   @value_answers = Array.new
   @values_answers = @ans.values.to_a
   serialized_hash = Marshal.dump(@ans)
   @file_id = session.user.id
   @hash = Marshal.load(serialized_hash)
     @pachecklist.attributes = { :answers => @text}
     @pachecklist.attributes = { :scv_perday => @scv_perday }
     @pachecklist.attributes = { :performed_by => @performed_by }
     @pachecklist.attributes = { :biz_location_id => @biz_location_id}
     @pachecklist.attributes = { :date_of_audit => @date_of_audit }
     @pachecklist.attributes = { :audit_period => @audit_period }

     @pachecklist.attributes = { :meeting_attended_during_ap => @meeting_attended_during_ap }
     @pachecklist.attributes = { :branch_management => @branch_management }
     @pachecklist.attributes = { :social_audit => @social_audit }
     @pachecklist.attributes = { :supervision => @supervision }
     @pachecklist.attributes = { :positive1 => @positive1 }
     @pachecklist.attributes = { :postive2 => @positive2 }
     @pachecklist.attributes = { :positive3 => @positive3 }
     @pachecklist.attributes = { :deviation1 => @deviation1 }
     @pachecklist.attributes = { :deviation2 => @deviation2 }
     @pachecklist.attributes = { :deviation3 => @deviation3 }
     
     if @pachecklist.save
      redirect resource(@pachecklist), :message => {:notice => "process audit checklist was successfully created"}
    else
      message[:error] = "process audit  failed to be created please enter valid integer values for qualitative fields"
      redirect url(:answers_pachecklists, :biz_location_id => @biz_location_id), :message => {:notice => "process audit failed to save,please enter valid integer values for qualitative fields "}
    end
  end 
  def edit(id)
    only_provides :html
   
    @pachecklist = Pachecklist.get(id)
    @biz_location_id = @pachecklist.biz_location_id
    @biz_location = BizLocation.get(@biz_location_id) 
    raise NotFound unless @pachecklist
    display @pachecklist
  end

  def create(pachecklist)
   
    @pachecklist = Pachecklist.new(pachecklist)
   @q1 = params[:q1_1]
   @q2 = params[:q2_2]
   @q3 = params[:q3_3]
   @q4 = params[:q4_4]
   @q5 = params[:q5_5]
   @q6 = params[:q6_6]
   @q7 = params[:q7_7]
   @q8 = params[:q8_8]
   @q9 = params[:q9_9]
   @q10 = params[:q10_10]
   @q11 = params[:q11_11]
   @q12 = params[:q12_12]
   @q13 = params[:q13_13]
   @q14 = params[:q14_14]
   @q15 = params[:q15_15]
   @q16 = params[:q16_16]
   @q17 = params[:q17_17]
   @q18 = params[:q18_18]
   @q19 = params[:q19_19]
   @q20 = params[:q20_20]
   @q21 = params[:q21_21]
   @q22 = params[:q22_22]
   @q23 = params[:q23_23]
   @q24 = params[:q24_24]
   @q25 = params[:q25_25]
   @q26 = params[:q26_26]
   @q27 = params[:q27_27]
   @q28 = params[:q28_28]
   @q29 = params[:q29_29]
   @q30 = params[:q30_30]
   @q31 = params[:q31_31]
   @q32 = params[:q32_32]
   @q33 = params[:q33_33]
   @q34 = params[:q34_34]
   @q35 = params[:q35_35]
   @q36 = params[:q36_36]
   @q37 = params[:q37_37]
   @q38 = params[:q38_38]
   @q39 = params[:q39_39]
   @q40 = params[:q40_40]
   @q41 = params[:q41_41]
   @q42 = params[:q42_42]
   @q43 = params[:q43_43]
   @q44 = params[:q44_44]
   @q45 = params[:q45_45]
   @q46 = params[:q46_46]
   @q47 = params[:q47_47]
   @q48 = params[:q48_48]
   @q49 = params[:q49_49]
   @q50 = params[:q50_50]
   @q51 = params[:q51_51]
   @q52 = params[:q52_52]
   @q53 = params[:q53_53]
   
   @ans = Hash.new
   @ans = { "q1_1" => @q1 , "q2_2" => @q2, "q3_3" => @q3, "q4_4" => @q4 , "q5_5" => @q5, 
           "q6_6" => @q6, "q7_7" => @q7, "q8_8" => @q8, "q9_9" => @q9, "q10_10" => @q10,
             "q11_11" => @q11, "q12_12" => @q12, "q13_13" => @q13, "q14_14" => @q14, 
            "q15_15" => @q15, "q16_16" => @q16, "q17_17" => @q17, "q18_18" => @q18,
            "q19_19" => @q19,"q20_20" => @q20, "q21_21" => @q21, "q22_22" => @q22,
            "Q23_23" => @q23, "q24_24" => @q24, "q25_25" => @q25, "q26_26" => @q26,
            "q27_27" => @q27, "q28_28" => @q28, "q29_29" => @q29, "q30_30" => @q30,
            "q31_31" => @q31, "q32_32" => @q32, "q33_33" => @q33, "q34_34" => @q34,
            "q35_35" => @q35, "q36_36" => @q36, "q37_37" => @q37, "q38_38" => @q38,
            "q39_39" => @q39, "q40_40" => @q40 , "q41_41" => @q41, "q42_42" => @q42,"q43_43" => @q43,
            "q44_44" => @q44, "q45_45" => @q45, "q46_46" => @q46, "q47_47" => @q47,
            "q48_48" => @q48, "q49_49" => @q49, "q50_50" => @q50, "q51_51" => @q51,
            "q52_52" => @q52, "q53_53" => @q53}
   @value_answers = Array.new
   @values_answers = @ans.values.to_a
   serialized_hash = Marshal.dump(@ans)
   @file_id = session.user.id
   @hash = Marshal.load(serialized_hash)
   @pachecklist.attributes = { :answers => @hash }
     if @pachecklist.save
     redirect url(:pachecklist,@pachecklist.id)
     end   
      redirect url(:pachecklist,@pachecklist.id)
	display @pachecklist
    if @pachecklist.save
      redirect resource(@pachecklist), :message => {:notice => "Pachecklist was successfully created"}
    else
      message[:error] = "Pachecklist failed to be created"
      render :new
    end
  end

  def update(id, pachecklist)
   @pachecklist = Pachecklist.get(id)
   @q1 = params[:q1_1]
   @q2 = params[:q2_2]
   @q3 = params[:q3_3]
   @q4 = params[:q4_4]
   @q5 = params[:q5_5]
   @q6 = params[:q6_6]
   @q7 = params[:q7_7]
   @q8 = params[:q8_8]
   @q9 = params[:q9_9]
   @q10 = params[:q10_10]
   @q11 = params[:q11_11]
   @q12 = params[:q12_12]
   @q13 = params[:q13_13]
   @q14 = params[:q14_14]
   @q15 = params[:q15_15]
   @q16 = params[:q16_16]
   @q17 = params[:q17_17]
   @q18 = params[:q18_18]
   @q19 = params[:q19_19]
   @q20 = params[:q20_20]
   @q21 = params[:q21_21]
   @q22 = params[:q22_22]
   @q23 = params[:q23_23]
   @q24 = params[:q24_24]
   @q25 = params[:q25_25]
   @q26 = params[:q26_26]
   @q27 = params[:q27_27]
   @q28 = params[:q28_28]
   @q29 = params[:q29_29]
   @q30 = params[:q30_30]
   @q31 = params[:q31_31]
   @q32 = params[:q32_32]
   @q33 = params[:q33_33]
   @q34 = params[:q34_34]
   @q35 = params[:q35_35]
   @q36 = params[:q36_36]
   @q37 = params[:q37_37]
   @q38 = params[:q38_38]
   @q39 = params[:q39_39]
   @q40 = params[:q40_40]
   @q41 = params[:q41_41]
   @q42 = params[:q42_42]
   @q43 = params[:q43_43]
   @q44 = params[:q44_44]
   @q45 = params[:q45_45]
   @q46 = params[:q46_46]
   @q47 = params[:q47_47]
   @q48 = params[:q48_48]
   @q49 = params[:q49_49]
   @q50 = params[:q50_50]
   @q51 = params[:q51_51]
   @q52 = params[:q52_52]
   @q53 = params[:q53_53]
   
   @ans = Hash.new
   @ans = { "q1_1" => @q1 , "q2_2" => @q2, "q3_3" => @q3, "q4_4" => @q4 , "q5_5" => @q5, 
           "q6_6" => @q6, "q7_7" => @q7, "q8_8" => @q8, "q9_9" => @q9, "q10_10" => @q10,
             "q11_11" => @q11, "q12_12" => @q12, "q13_13" => @q13, "q14_14" => @q14, 
            "q15_15" => @q15, "q16_16" => @q16, "q17_17" => @q17, "q18_18" => @q18,
            "q19_19" => @q19,"q20_20" => @q20, "q21_21" => @q21, "q22_22" => @q22,
            "Q23_23" => @q23, "q24_24" => @q24, "q25_25" => @q25, "q26_26" => @q26,
            "q27_27" => @q27, "q28_28" => @q28, "q29_29" => @q29, "q30_30" => @q30,
            "q31_31" => @q31, "q32_32" => @q32, "q33_33" => @q33, "q34_34" => @q34,
            "q35_35" => @q35, "q36_36" => @q36, "q37_37" => @q37, "q38_38" => @q38,
            "q39_39" => @q39, "q40_40" => @q40 , "q41_41" => @q41, "q42_42" => @q42,"q43_43" => @q43,
            "q44_44" => @q44, "q45_45" => @q45, "q46_46" => @q46, "q47_47" => @q47,
            "q48_48" => @q48, "q49_49" => @q49, "q50_50" => @q50, "q51_51" => @q51,
            "q52_52" => @q52, "q53_53" => @q53}

    @file_id = session.user.id
    serialized_hash = Marshal.dump(@ans)
   

     @hash = Marshal.load(serialized_hash)

     @pachecklist.attributes = { :answers => @hash }
    raise NotFound unless @pachecklist
    if @pachecklist.update(pachecklist)
      @pachecklist.attributes = { :answers => @hash }
       redirect url(:pachecklist,@pachecklist.id)
    else
      display @pachecklist, :edit
    end
  end

  def destroy(id)
    @pachecklist = Pachecklist.get(id)
    raise NotFound unless @pachecklist
    if @pachecklist.destroy
      redirect resource(:pachecklists)
    else
      raise InternalServerError
    end
  end

end # Pachecklists
