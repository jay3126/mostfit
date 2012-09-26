if defined?(Merb::Plugins)

  $:.unshift File.dirname(__FILE__)

  dependency 'merb-slices', :immediate => true
  Merb::Plugins.add_rakefiles "checklister_slice/merbtasks", "checklister_slice/slicetasks", "checklister_slice/spectasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :checklister_slice
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:checklister_slice][:layout] ||= :checklister_slice
  
  # All Slice code is expected to be namespaced inside a module
  module ChecklisterSlice
    
    # Slice metadata
    self.description = "This is a slice created by Ptotem for checklist functionality"
    self.version = "0.0.1"
    self.author = "Rushabh Hathi"
    
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded

    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(ChecklisterSlice)
    def self.deactivate
    end
    
    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any 
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :rushabh_slice_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
      scope.resources :checklists
      scope.resources :checklist_types
      scope.resources :checklist_locations

      scope.resources :checkpoints
      scope.resources :checkpoint_fillings
      scope.resources :fillers
      scope.resources :free_texts
      scope.resources :free_text_fillings
      scope.resources :responses
      scope.resources :sections
      scope.resources :section_types
      scope.resources :target_entities

      scope.match('/responses/view_checklist_responses/:id').to(:controller => 'responses', :action => 'view_checklist_responses').name(:view_checklist_responses)

      scope.match('/checklists/fill_in_checklist/:id').to(:controller => 'checklists', :action => 'fill_in_checklist').name(:fill_in_checklist)
      scope.match('/checklists/capture_checklist_data').to(:controller => 'checklists', :action => 'capture_checklist_data').name(:capture_checklist_data)
      scope.match('/responses/view_response/:id').to(:controller => 'responses', :action => 'view_response').name(:view_response)
      scope.match('/responses/edit_response/:id').to(:controller => 'responses', :action => 'edit_response').name(:edit_response)
      scope.match('/responses/view_report/:id').to(:controller => 'responses', :action => 'view_report').name(:view_report)


     # example of a named route
#      scope.match('/index(.:format)').to(:controller => 'main', :action => 'index').name(:index)
      # the slice is mounted at /checklister_slice - note that it comes before default_routes
 #     scope.match('/').to(:controller => 'main', :action => 'index').name(:home)
      #scope.match('/checklist_types/new(.:format)').to(:controller => 'checklist_types',:action=>"new").name(:checklist_types)
      # enable slice-level default routes by default
      scope.match('/check/:controller(/:action)').register

      scope.default_routes
    end
    
  end
  
  # Setup the slice layout for ChecklisterSlice
  #
  # Use ChecklisterSlice.push_path and ChecklisterSlice.push_app_path
  # to set paths to checklister_slice-level and app-level paths. Example:
  #
  # ChecklisterSlice.push_path(:application, ChecklisterSlice.root)
  # ChecklisterSlice.push_app_path(:application, Merb.root / 'slices' / 'checklister_slice')
  # ...
  #
  # Any component path that hasn't been set will default to ChecklisterSlice.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  ChecklisterSlice.setup_default_structure!
  
  # Add dependencies for other ChecklisterSlice classes below. Example:
  # dependency "checklister_slice/other"

end

