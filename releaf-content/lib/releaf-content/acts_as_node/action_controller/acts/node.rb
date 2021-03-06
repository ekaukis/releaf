module ActionController
  module Acts #:nodoc:
    module Node #:nodoc:
      def self.included(base)
        base.extend(::ActsAsNode::ClassMethods)
        base.extend(ClassMethods)
      end

      # This +acts_as+ extension provides the capabilities for attaching object to nodes tree.
      #
      # Text example:
      #
      #   class ContactFormController < ActionController::Base
      #     has_many :acts_as_node
      #   end
      #
      module ClassMethods
        # There are no configuration options yet.
        #
        def acts_as_node(options = {})
          super options
        end
      end

    end
  end
end
