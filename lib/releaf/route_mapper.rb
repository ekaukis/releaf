module Releaf::RouteMapper
  # Pass given resource to "resources" mount method and
  # add extra routes for members and collections needed by releaf
  def releaf_resources(*args, &block)
    resources *args do
      yield if block_given?
      get   :confirm_destroy, :on => :member      if include_confirm_destroy?(args.last)
    end
  end

  def mount_releaf_at mount_location, options={}, &block
    controllers = allowed_controllers(options)

    post '/tinymce_assets' => 'releaf/tinymce_assets#create' if controllers.include? :content

    devise_for Releaf.devise_for, path: mount_location, controllers: { sessions: "releaf/sessions" }

    mount_location_namespace = mount_location.gsub("/", "").to_sym
    scope mount_location do
      if mount_location_namespace.empty?
        yield if block_given?
      else
        namespace mount_location_namespace, :path => nil do
          yield if block_given?
        end
      end

      namespace :releaf, :path => nil do
        releaf_resources :admins if controllers.include? :admins
        releaf_resources :roles if controllers.include? :roles

        mount_admin_profile_controller if controllers.include? :admin_profile
        mount_content_controller if controllers.include? :content
        mount_translations_controller if controllers.include? :translations

        root :to => "home#index"
        get '/*path' => 'base_application#page_not_found'
      end
    end
  end

  private

  # Get list of allowed releaf built-in controllers
  def allowed_controllers options
    allowed_controllers = options.try(:[], :allowed_controllers)
    if allowed_controllers.nil?
      allowed_controllers = [:roles, :admins, :translations, :admin_profile, :content]
    end

    allowed_controllers
  end

  # Mount translations controller
  def mount_translations_controller
    releaf_resources :translation_groups, :controller => "translations", :path => "translations", :except => [:show] do
      member do
        get :export
        post :import
      end
    end
  end

  # Mount admin profile controller
  def mount_admin_profile_controller
    get "profile", to: "admin_profile#edit", as: :admin_profile
    put "profile", to: "admin_profile#update", as: :admin_profile
    post "profile/settings", to: "admin_profile#settings", as: :admin_profile_settings
  end

  # Mount nodes content controller
  def mount_content_controller
    releaf_resources :nodes, :controller => "content", :path => "content", :except => [:show] do
      collection do
        get :generate_url
        get :go_to_dialog
      end

      member do
        get :copy_dialog
        post :copy
        get :move_dialog
        post :move
      end
    end
  end

  # Check whether add confirm destroy route
  def include_confirm_destroy? options
    add_confirm_destroy = true
    if options.is_a? Hash
      if options[:only] && !options[:only].include?(:destroy)
        add_confirm_destroy = false
      elsif options[:except].try(:include?, :destroy)
        add_confirm_destroy = false
      end
    end

    return add_confirm_destroy
  end
end # Releaf::RouteMapper