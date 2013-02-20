require 'active_support/core_ext'
require 'active_support/cache'
require 'logger'
require 'cache_digests/dependency_tracker'

module CacheDigests
  class TemplateDigestor
    cattr_accessor(:cache) { ActiveSupport::Cache::MemoryStore.new }
    cattr_accessor(:cache_prefix)

    cattr_accessor(:logger, instance_reader: true)

    def self.digest(name, format, finder, options = {})
      cache_key = [ "digestor", cache_prefix, name, format, *Array.wrap(options[:dependencies]) ].compact.join("/")
      cache.fetch(cache_key) do
        cache.write(cache_key, nil) # Prevent re-entry
        new(name, format, finder, options).digest
      end
    end

    attr_reader :name, :format, :finder, :options

    def initialize(name, format, finder, options = {})
      @name, @format, @finder, @options = name, format, finder, options
    end

    def digest
      Digest::MD5.hexdigest("#{source}-#{dependency_digest}").tap do |digest|
        logger.try :info, "Cache digest for #{name}.#{format}: #{digest}"
      end
    rescue ActionView::MissingTemplate
      logger.try :error, "Couldn't find template for digesting: #{name}.#{format}"
      ''
    end

    def dependencies
      DependencyTracker.find_dependencies(name, template)
    rescue ActionView::MissingTemplate
      [] # File doesn't exist, so no dependencies
    end

    def nested_dependencies
      dependencies.collect do |dependency|
        dependencies = TemplateDigestor.new(dependency, format, finder, partial: true).nested_dependencies
        dependencies.any? ? { dependency => dependencies } : dependency
      end
    end

    private
      def logical_name
        name.gsub(%r|/_|, "/")
      end

      def partial?
        options[:partial] || name.include?("/_")
      end

      def source
        template.source
      end

      def template
        @template ||= finder.find(logical_name, [], partial?, formats: [ format ])
      end

      def dependency_digest
        template_digests = dependencies.collect do |template_name|
          TemplateDigestor.digest(template_name, format, finder, partial: true)
        end

        (template_digests + injected_dependencies).join("-")
      end

      def injected_dependencies
        Array.wrap(options[:dependencies])
      end
  end
end
