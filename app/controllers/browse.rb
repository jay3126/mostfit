class Browse < Application
  provides :xml 
  before :display_from_cache, :only => [:hq_tab]
  after  :store_to_cache,     :only => [:hq_tab]
  Line = Struct.new(:ip, :date_time, :method, :model, :url, :status, :response_time)
  
  def index
    set_effective_date(Date.today) if session[:effective_date].blank?
    render
  end

  def hq_tab
    partial :totalinfo
  end

  # method to parse log file and show activity. 
  def show_log
    @@models ||=  DataMapper::Model.descendants.map{|d| [d.to_s.snake_case.pluralize, d]}.to_hash
    @@not_reported_controllers ||= ["merb_auth_slice_password/sessions", "exceptions", "entrance", "login", "searches"]
    @lines = []
    ignore_regex = /\/images|\/javascripts|\/stylesheets|\/open-flash-chart|\/searches|\/dashboard|\/graph_data|\/browse/
    `tail -500 log/#{Merb.env}.log`.split(/\n/).reverse.each{|line|
      next if ignore_regex.match(line)
      ip, date_time, timezone, method, uri, http_type, status, size, response_time  = line.strip.gsub(/(\s\-\s)|\[|\]|\"/, "").split(/\s/).reject{|x| x==""}
      uri = URI.parse(uri)
      method = method.to_s.upcase || "GET"
      request = Merb::Request.new(
                                  Merb::Const::REQUEST_PATH => uri.path,
                                  Merb::Const::REQUEST_METHOD => method,
                                  Merb::Const::QUERY_STRING => uri.query ? CGI.unescape(uri.query) : "")
      route = Merb::Router.match(request)[1] rescue nil
      route.merge!(uri.query.split("&").map{|x| x.split("=")}.to_hash) if uri.query

      next if not route[:controller] or @@not_reported_controllers.include?(route[:controller])
      model = @@models[route[:controller]] if @@models.key?(route[:controller])
      @lines.push(Line.new(ip, date_time, method.downcase.to_sym, model, route, status.to_i, response_time.split(/\//)[0]))
    }
    render
  end
end
