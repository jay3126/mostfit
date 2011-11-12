module DataEntry
  class Clients < DataEntry::Controller
    provides :html, :xml
    def new
      params[:return] = "/data_entry"
      @center  = Center.get(params[:client][:center_id]) if params[:client] and params[:client][:center_id] 
      @branch = @center.branch if @center
      if Client.descendants.count == 1
        only_provides :html
        @client = Client.new
        display @client, "clients/new"
      else
        if params[:client_type]
          @client = Kernel.const_get(params[:client_type].camel_case).new
          display @client, "clients/new"
        else
          render :template => "clients/new"
        #  params[:return] = "/data_entry"
         # request.xhr? ? display([@client], "clients/new", :layout => false) : display([@client], "clients/new")
        end
      end
    end
    
    def edit
      if (params[:id] and @client = Client.get(params[:id])) or (params[:client_id] and @client = Client.get(params[:client_id]) || Client.first(:name => params[:client_id]) || Client.first(:reference => params[:client_id]))
        @center = @client.center
        @branch = @center.branch
        params[:return] = "/data_entry"
        request.xhr? ? display([@client], "clients/edit", :layout => false) : display([@client], "clients/edit")
      elsif params[:client_id]
        message[:error] = "No client by that id or name or reference number"
        display([@center], "clients/search")
      elsif params[:client] and params[:client][:center_id]
        @center  = Center.get(params[:client][:center_id])
        display([@center], "clients/search")
      else
        display([], "clients/search")
      end
    end
    
    def add_guarantor
      
      if params[:client] and params[:client][:center_id]
        @center  = Center.get(params[:client][:center_id])
        display([@center], "clients/add_guarantor_by_center")
      else
        display([], "clients/add_guarantor_by_center")
      end
    end
    
  end
end
