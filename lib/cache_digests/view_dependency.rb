module CacheDigests
  module ViewDependency
    extend ActiveSupport::Concern

    included do
      class_attribute :_view_dependencies
      self._view_dependencies = []

      helper_method :view_dependencies
    end

    module ClassMethods
      def view_dependency(&dependency)
        self._view_dependencies += [dependency]
      end
    end

    def view_dependencies
      self.class._view_dependencies.map { |dep| instance_exec &dep }.compact
    end
  end
end
