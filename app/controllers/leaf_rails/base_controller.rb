module LeafRails
  class BaseController < ActionController::Base
    before_filter :authenticate_admin!
    layout 'leaf_rails/admin'
    protect_from_forgery

    before_filter do
      filter_templates
      set_locale
      setup
    end

    def setup
      @controller        = self # this is used later in views
      @features          = { :create => true, :show => true, :edit => true, :destroy => true}
      @panel_layout      = true
      @continuous_scroll = false
      @items_per_page    = 40
      @secondary_panel   = render_to_string( :partial => "secondary_panel", :layout => false, :locals => build_secondary_panel_variables)
    end

    def continuous_scroll
      @continuous_scroll
    end

    def items_per_page
      @items_per_page
    end

    def features
      @features
    end

    def panel_layout
      @panel_layout
    end

    def build_secondary_panel_variables
      raise RuntimeError, "Not implemented"
    end

    def current_object_class
      self.class.name.sub(/^.*::/, '').sub(/\s?Controller$/, '').classify.constantize
    end

    def columns( view = nil )
      return current_object_class.column_names - ['id', 'created_at', 'updated_at']
    end

    def list_action
      if !cookies['base_module:list_action'].blank?
        feature = cookies['base_module:list_action']
        if feature == 'confirm_destroy'
          feature = 'destroy'
        end
        feature = feature.to_sym
        if !@features[ feature ].blank?
          return cookies['base_module:list_action']
        end
      end
      if !@features[ :show ].blank?
        return 'show'
      end
      return 'edit';
    end

    def has_template( name )
      lookup_context.template_exists?( name, lookup_context.prefixes, false )
    end

    def find_parent_template( name )
      lookup_context.find_template( name, lookup_context.prefixes.slice( 1, lookup_context.prefixes.length ), false )
    end

    def render_parent_template( name, locals = {} )
      template = find_parent_template( name )
      if template.blank?
        return 'blank'
      end
      arguments = { :layout => false, :locals => locals, :template => template.virtual_path }
      return render_to_string( arguments ).html_safe
    end

    def input_type_for( column_type, name )
      input_type = 'text'
      case column_type
      when :boolean
        input_type = 'checkbox'
      when :text
        input_type = 'textarea'
        if name.end_with?( '_html' )
          input_type = 'richtext'
        end
      end
      return input_type
    end

    # actions

    def index
      if current_object_class.respond_to?( :filter )
        @list = current_object_class.filter(:search => params[:search])
      else
        @list = current_object_class
      end
      @list = @list.page( params[:page] ).per_page( items_per_page )
      if !params[:ajax].blank?
        render :layout => false
      end
    end

    def urls
      respond_to do |format|
        format.json do
          json = {}
          params[:ids].each do |id|
            json[id] = url_for( :action => params[:to_action], :id => id, :only_path => true )
          end
          render :json => json, :layout => false
        end
      end
    end

    def new
      @item = current_object_class.new
    end

    def show
      @item = current_object_class.find(params[:id])
    end

    def edit
      @item = current_object_class.find(params[:id])
    end

    def create
      @item = current_object_class.new

      if @item.respond_to? :allowed_params
        variables = params.require( current_object_class.to_s.underscore ).permit( *@item.allowed_params(:create) )
      else
        variables = params.require( current_object_class.to_s.underscore ).permit( *current_object_class.column_names )
      end

      @item.assign_attributes( variables )

      respond_to do |format|
        if @item.save
          format.html { redirect_to url_for( :action => 'show', :id => @item.id ) }
        else
          format.html { render :action => "new" }
        end
      end
    end

    def update
      @item = current_object_class.find(params[:id])

      if @item.respond_to? :allowed_params
        variables = params.require( current_object_class.to_s.underscore ).permit( *@item.allowed_params(:update) )
      else
        variables = params.require( current_object_class.to_s.underscore ).permit( *current_object_class.column_names )
      end

      respond_to do |format|
        if @item.update_attributes( variables )
          format.html { redirect_to url_for( :action => 'show', :id => @item.id ) }
        else
          format.html { render :action => "edit" }
        end
      end
    end

    def confirm_destroy
      @item = current_object_class.find(params[:id])
    end

    def destroy
      @item = current_object_class.find(params[:id])
      @item.destroy

      respond_to do |format|
        format.html { redirect_to url_for( :action => 'index' ) }
      end
    end


    private

    def set_locale
      I18n.locale = if params[:locale] && Settings.i18n_locales.include?(params[:locale])
        params[:locale]
      elsif cookies[:locale] && Settings.i18n_locales.include?(cookies[:locale])
        cookies[:locale]
      else
        I18n.default_locale
      end
    end

    def filter_templates
      filter_templates_from_hash params
    end

    def filter_templates_from_array arr
      return unless arr.is_a? Array
      arr.each do |item|
        if item.is_a? Hash
          filter_templates_from_hash item
        elsif item.is_a? Array
          filter_templates_from_array item
        end
      end
    end

    def filter_templates_from_hash hsk
      return unless hsk.is_a? Hash
      hsk.delete :_template_
      hsk.delete '_template_'

      filter_templates_from_array hsk.values
    end

  end
end