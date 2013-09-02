module Releaf
  class Node::Route
    attr_accessor :path, :node, :locale, :node_id

    # Return node route params which can be used in Rails route options
    #
    # @param args [String] string with action and controller for route (Ex. home#index)
    # @param args [Hash] options to merge with internally built params. Passed params overrides route params.
    # @return [Hash] route options. Will return at least node "node_id" and "locale" keys.
    def params controller_action, args = {}
      route_params = {
        node_id: node_id,
        locale: locale
      }

      route_params.merge!(args)

      # normalize as with locale
      unless locale.blank? || route_params[:as].blank?
        route_params[:as] = "#{locale}_#{route_params[:as]}"
      end

      route_params[path] = controller_action

      route_params
    end

    # Return routes for given class that implement ActsAsNode
    #
    # @param class_name [Class] class name to load related nodes
    # @return [Array] array of Node::Route objects
    def self.for class_name
      routes = []

      if nodes_available?
        Node.where(content_type: class_name).each do|node|
          routes << build_route_object(node)
        end
      end

      routes
    end

    private

    # Build Node::Route from Node object
    def self.build_route_object node
      route = Node::Route.new
      route.node_id = node.id
      route.path = node.url
      route.locale = node.root.locale

      route
    end

    # Check for nodes table availability
    def self.nodes_available?
      ActiveRecord::Base.connection.table_exists? 'releaf_nodes'
    end
  end
end