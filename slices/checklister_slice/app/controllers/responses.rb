class ChecklisterSlice::Responses < ChecklisterSlice::Application
  # provides :xml, :yaml, :js

  def index
    @responses = Response.all
    display @responses
  end

  def show(id)
    @response = Response.get(id)
    raise NotFound unless @response
    display @response
  end

  def new
    only_provides :html
    @response = Response.new
    display @response
  end

  def edit(id)
    only_provides :html
    @response = Response.get(id)
    raise NotFound unless @response
    display @response
  end

  def create(response)
    @response = Response.new(response)
    raise @response.inspect
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
            "q43_43" => @q44, "q45_45" => @q45, "q46_46" => @q46, "q47_47" => @q47,
            "q48_48" => @q48, "q49_49" => @q49, "q50_50" => @q50, "q51_51" => @q51,
            "q52_52" => @q52, "q53_53" => @q53}
   @value_answers = Array.new
   @values_answers = @ans.values.to_a
 #  raise @values_answers.inspect
   serialized_hash = Marshal.dump(@ans)
   # @file_id =  Time.now.getutc.to_s
   @file_id = session.user.id
    File.open(Merb.root/"#{@file_id}.json", 'w') {|f| f.write(serialized_hash) }
    hash = Marshal.load File.read(Merb.root/"#{@file_id}.json")
     @response.attributes = { :answers => "#{@file_id}.json" }
    if @response.save
      redirect resource(@response), :message => {:notice => "Response was successfully created"}
    else
      message[:error] = "Response failed to be created"
      render :new
    end
  end

  def update(id, response)
    @response = Response.get(id)
    raise NotFound unless @response
    if @response.update(response)
      redirect resource(@response)
    else
      display @response, :edit
    end
  end

  def destroy(id)
    @response = Response.get(id)
    raise NotFound unless @response
    if @response.destroy
      redirect resource(:responses)
    else
      raise InternalServerError
    end
  end

  def view_checklist_responses(id)
    @checklist=Checklist.get(id)
    @responses=@checklist.responses
    @fillers=Filler.all
    display @responses
  end


  def view_response(id, response_id)
    @filler=Filler.get(id)

    @response=Response.get(params[:response_id])
    @checklist=@response.checklist
    @sections=@checklist.sections
    display @responses
  end

  def edit_response(id, response_id)
    @filler=Filler.get(id)

    @response=Response.get(params[:response_id])
    @checklist=@response.checklist
    @sections=@checklist.sections
    display @responses
  end

  def view_report(id,response_id,checklist_id)
    @checklist=Checklist.get(checklist_id)
    @response=Response.get(response_id)
    @sections=@checklist.sections.all(:has_score=>true)

     display @response

  end
end # Responses
