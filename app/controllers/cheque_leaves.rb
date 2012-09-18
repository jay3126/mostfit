class ChequeLeaves < Application

  def edit(id)
    only_provides :html
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    display @cheque_leaf
  end

  def update(id, cheque_leaf)
    @cheque_leaf = ChequeLeaf.get(id)
    raise NotFound unless @cheque_leaf
    query = params[:cheque_leaf][id].first
    if @cheque_leaf.update!(query)
      redirect url("cheque_books/show/#{@cheque_leaf.cheque_book_id}"), :message => {:notice => "Details for cheque leaf with serial number: #{@cheque_leaf.serial_number} successfully updated"}
    else
      display @cheque_leaf
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
