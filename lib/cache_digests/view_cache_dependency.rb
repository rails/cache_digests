module CacheDigests
  module ViewCacheDependency
    extend ActiveSupport::Concern

    included do
      class_attribute :_view_cache_dependencies
      self._view_cache_dependencies = []

      helper_method :view_cache_dependencies
    end

    module ClassMethods
      def view_cache_dependency(&dependency)
        self._view_cache_dependencies += [dependency]
      end
    end

    def view_cache_dependencies
      self.class._view_cache_dependencies.map { |dep| instance_exec &dep }.compact
    end
  end
end
