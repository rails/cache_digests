module CacheDigests
  module FragmentHelper
    def fragment_name_with_digest(name, dependencies)
      [*name, TemplateDigestor.digest(@virtual_path, formats.last.to_sym, lookup_context, dependencies: dependencies)]
    end

    private
      # Automatically include this template's digest -- and its childrens' --
      # in the cache key. Cache digests can be skipped by either providing an
      # explicitly versioned key (an Array-based key with the first key
      # matching "v#" e.g. ['v3','my-key']) or by passing skip_digest: true to
      # the options hash.
      #
      # "view_dependencies" method is a helper defined in the ViewDependency
      # module, which is declared as a helper by the controller.
      def fragment_for(key, options = nil, &block)
        skip_digest = explicitly_versioned_cache_key?(key) ||
          (options && options.delete(:skip_digest))

        if !skip_digest
          with_cache_prefix view_dependencies do |dependencies|
            super fragment_name_with_digest(key, dependencies), options, &block
          end
        else
          super
        end
      end

      def explicitly_versioned_cache_key?(key)
        key.is_a?(Array) && key.first =~ /\Av\d+\Z/
      end

      # If view dependencies have been specified programmatically, we need
      # to also set a new cache_prefix, so that the previously cached cache digest
      # is not used. (Dependencies are not used to build the digest's cache key.)
      def with_cache_prefix(dependencies)
        if dependencies.any?
          old_prefix = CacheDigests::TemplateDigestor.cache_prefix
          new_prefix = dependencies.join('.')

          begin
            CacheDigests::TemplateDigestor.cache_prefix = new_prefix
            yield dependencies
          ensure
            CacheDigests::TemplateDigestor.cache_prefix = old_prefix
          end
        else
          yield dependencies
        end
      end
  end
end
