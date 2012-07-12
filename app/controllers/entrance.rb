class Entrance < Merb::Controller  # not inherit from Application as that thing is authenticated

  def index
    render
  end

  def about
    render
  end

  def root
    #    redirect url(:entrance)  # no switch, nicer for the demo
    if session.authenticated?
      redirect url(:home)  # this should be the cockpit page in later versions
    else
      redirect url(:entrance)
    end
  end

  def handshake
    only_provides :xml
    display @template
  end
end
