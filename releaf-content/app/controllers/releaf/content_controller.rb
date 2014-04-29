module Releaf
  class ContentController < BaseController

    def index
      @collection = resource_class.roots
    end

    def generate_url
      tmp_resource = prepare_resource

      tmp_resource.name = params[:name]
      tmp_resource.slug = nil
      # FIXME calling private method
      tmp_resource.send(:ensure_unique_url)

      respond_to do |format|
        format.js { render text: tmp_resource.slug }
      end
    end

    def new
      new_common
      super

      respond_to do |format|
        format.html do
          render layout: nil if ajax?
        end
      end
    end

    def copy_dialog
      copy_move_dialog_common
    end

    def move_dialog
      copy_move_dialog_common
    end

    def copy
      source_node = resource_class.find(params[:id])

      begin
        @resource = source_node.copy_to_node! params[:new_parent_id]
      rescue ActiveRecord::RecordInvalid => e
        @resource = e.record
        copy_move_common false
      else
        copy_move_common true
      end
    end

    def move
      @resource = resource_class.find(params[:id])

      begin
        @resource.move_to_node! params[:new_parent_id]
      rescue ActiveRecord::RecordInvalid => e
        copy_move_common false
      else
        copy_move_common true
      end
    end

    def go_to_dialog
      @collection = resource_class.roots

      respond_to do |format|
        format.html do
          render layout: nil
        end
      end
    end

    # Override base controller create method
    # so we can assign content_type before further
    # processing
    def create
      new_common
      super
    end

    def edit
      super do
        edit_common
      end
    end

    def update
      super do
        edit_common
      end
    end

    # override base_controller method for adding content tree ancestors
    # to breadcrumbs
    def add_resource_breadcrumb resource
      ancestors = []
      if resource.new_record?
        if resource.parent_id
          ancestors = resource.parent.ancestors
          ancestors += [resource.parent]
        end
      else
        ancestors = resource.ancestors
      end

      ancestors.each do |ancestor|
        @breadcrumbs << { name: ancestor, url: url_for( action: :edit, id: ancestor.id ) }
      end

      super resource
    end

    def self.resource_class
      # TODO class name should be configurable
      ::Node
    end

    private

    def copy_move_common result
      if result
        @resource.update_settings_timestamp
        render_notification true
      end

      respond_to do |format|
        format.json do
          if result
            render json: {url: url_for( action: :index ), message: flash[:success][:message]}, status: 303
          else
            render json: Releaf::ResourceValidator.build_validation_errors(@resource, controller_scope_name), status: 422
          end
        end

        format.html do
          render_notification false unless result
          redirect_to url_for( action: :index )
        end
      end
    end

    def copy_move_dialog_common
      @node = resource_class.find params[:id]
      @collection = resource_class.roots

      respond_to do |format|
        format.html do
          render layout: nil
        end
      end
    end

    def prepare_resource
      if params[:id]
        return resource_class.find(params[:id])
      elsif params[:parent_id].blank? == false
        parent = resource_class.find(params[:parent_id])
        return parent.children.new
      else
        return resource_class.new
      end
    end

    def copy_node node, new_parent_id, delete_original = false
      return unless node.instance_of?(resource_class)
      method_to_call = :copy_to_node
      method_to_call = :move_to_node if delete_original

      error = nil
      begin
        error = node.send(method_to_call, new_parent_id).nil?
      rescue ActiveRecord::RecordInvalid
        error = true
      end

      render_notification !error

      redirect_to :action => "index"
    end

    def edit_common
      @order_nodes = resource_class.where(parent_id: @resource.parent_id).where('id != :id', id: params[:id])

      if @resource.higher_item
        @item_position = @resource.item_position
      else
        @item_position = 1
      end
    end

    def new_common
      @resource = resource_class.new do |node|
        if params[:content_type].blank?
          @content_types = resource_class.valid_node_content_classes(params[:parent_id]).sort { |a, b| a.name <=> b.name }
        else
          @order_nodes = resource_class.where(parent_id: params[:parent_id])
          node.item_position ||= @order_nodes.to_a.inject(0) { |max, node| node.item_position + 1 > max ? node.item_position + 1 : max }

          node.content_type = node_content_class.name
          node.parent_id = params[:parent_id]

          if node_content_class < ActiveRecord::Base
            node.build_content({})
            node.content_id_will_change!
          end
        end
      end
    end

    # Returns valid content type class
    def node_content_class
      unless ActsAsNode.classes.include? params[:content_type]
        raise ArgumentError, "invalid content_type"
      end

      params[:content_type].constantize
    end

    def resource_params
      res_params = super
      res_params += [{content_attributes: permitted_content_attributes}]
      res_params -= %w[content_type]
      return res_params
    end

    def permitted_content_attributes
      @resource.content_class.acts_as_node_configuration[:permit_attributes]
    end
  end
end
