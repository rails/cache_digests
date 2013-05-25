module CacheDigests
  class Engine < ::Rails::Engine
    initializer 'cache_digests' do |app|
      require 'cache_digests'

      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, CacheDigests::FragmentHelper
        unless ActionView::Base.cache_template_loading
          CacheDigests::TemplateDigestor.cache = ActiveSupport::Cache::NullStore.new
        end
      end

      ActiveSupport.on_load :action_controller do
        ActionController::Base.send :include, CacheDigests::ViewCacheDependency
      end

      config.to_prepare do
        CacheDigests::TemplateDigestor.logger = Rails.logger
        DependencyTracker.register_tracker :erb, DependencyTracker::ERBTracker
      end
    end
  end
end
