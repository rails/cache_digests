require 'active_support/core_ext/array/access'
require 'active_support/core_ext/class/attribute_accessors'

module CacheDigests
  class TemplateDigestor
    EXPLICIT_DEPENDENCY = /<%# Template Dependency: ([^ ]+) %>/

    # Matches:
    #   render partial: "comments/comment", collection: commentable.comments
    #   render "comments/comments"
    #   render 'comments/comments'
    #   render('comments/comments')
    RENDER_DEPENDENCY = /
      render\s?      # render, followed by an optional space
      \(?            # start a optional parenthesis for the render call
      (partial:)?\s? # naming the partial, used with collection -- 1st capture
      (\"|\'){1}     # need starting quote of some kind to signify string-based template -- 2nd capture
      ([^'"]+)       # the template name itself -- 3rd capture
      (\"|\'){1}     # need closing quote of some kind to signify string-based template -- 4th capture
    /x

    # Class-level cache for the digests. To clear the cache, just do TemplateDigestor.cache.clear
    cattr_accessor(:cache) { Hash.new }

    def self.digest(name, format, finder, options = {})
      cache["#{name}.#{format}"] ||= new(name, format, finder, options).digest
    end

    attr_reader :name, :format, :finder, :options

    def initialize(name, format, finder, options = {})
      @name, @format, @finder, @options = name, format, finder, options
    end

    def digest
      Digest::MD5.hexdigest "#{name}.#{format}-#{source}-#{dependency_digest}"
    end


    private
      def logical_name
        name.gsub(%r|/_|, "/")
      end

      def partial?
        options[:partial] || name.include?("/_")
      end

      def source
        @source ||= finder.find(logical_name, [], partial?, formats: [ format ]).source
      end


      def dependency_digest
        dependencies.collect do |template_name|
          TemplateDigestor.digest(template_name, format, finder, partial: true)
        end.join("-")
      end

      def dependencies
        render_dependencies + explicit_dependencies
      end

      def render_dependencies
        source.scan(RENDER_DEPENDENCY).collect(&:third).uniq.reject { |template_name| template_name.include?("@") }
      end

      def explicit_dependencies
        source.scan(EXPLICIT_DEPENDENCY).flatten.uniq
      end
  end
end