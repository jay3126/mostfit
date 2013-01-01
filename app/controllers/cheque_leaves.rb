class ChequeLeaves < Application

  def edit(id)
    only_provides :html
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    display @cheque_leaf
  end

  def update(id, cheque_leaf)
    message ={}
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    #Gate Keeping
    @cheque_leaf_issue_date = params[:cheque_leaf][id].first[:cheque_issue_date]

    #Validations
    message[:error] = "Date cannot be blank" if @cheque_leaf_issue_date.blank?
      if message[:error].blank?

      message[:error] = "Cheque Leaf issue date cannot be before Cheque Book issue date" if Date.parse(@cheque_leaf_issue_date) < @cheque_leaf.cheque_book.issue_date

      query = params[:cheque_leaf][id].first
        if message[:error].blank?
           if @cheque_leaf.update!(query)
           message = {:notice => "Details for cheque leaf with serial number: #{@cheque_leaf.serial_number} successfully updated"}
           else
           display @cheque_leaf
           end

        else

        message = {:error => "Cheque Book falied to be created because : #{message[:error]}"}
        end

     else
     message = {:error => "Cheque Book falied to be created because : #{message[:error]}"}
     end
    #REDIRECT/RENDER
    if message[:error].blank?
      redirect request.referer, :message => message
    else
      redirect request.referer, :message => message
    end
 
  end

  def destroy(id)
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    if @cheque_leaf.destroy
      redirect resource(:cheque_leaves)
    else
      raise InternalServerError
    end
  end
  
  def mark_invalid(id)
    @id = id
    @cheque_leaf = ChequeLeaf.get(id)
    @cheque_leaf.update!(:valid => false)
    redirect url("cheque_books/show/#{@cheque_leaf.cheque_book_id}"), :message => {:notice => "Cheque Leaves marked as In-Valid successfully"}
  end

  def mark_valid(id)
    @cheque_leaf = ChequeLeaf.get(id)
    @cheque_leaf.update!(:valid => true)
    redirect url("cheque_books/show/#{@cheque_leaf.cheque_book_id}"), :message => {:notice => "Cheque Leaves marked as Valid successfully"}
  end

end # ChequeLeaves
