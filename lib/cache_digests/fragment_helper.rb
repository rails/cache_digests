module CacheDigests
  module FragmentHelper
    def fragment_name_with_digest(name)
      [*key, TemplateDigestor.digest(@virtual_path, formats.last.to_sym, lookup_context)]
    end

    private
      # Automatically include this template's digest -- and its childrens' -- in the cache key.
      def fragment_for(key, options = nil, &block)
        if !explicitly_versioned_cache_key?(key)
          super fragment_name_with_digest(key), options, &block
        else
          super
        end
      end

      def explicitly_versioned_cache_key?(key)
        key.is_a?(Array) && key.first =~ /\Av\d+\Z/
      end
  end
end
