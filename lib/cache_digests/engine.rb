module CacheDigests
  class Engine < ::Rails::Engine
    initializer 'cache_digests' do |app|
      require 'cache_digests'

      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, CacheDigests::FragmentHelper

        handler = ActionView::Template::Handlers::ERB
        tracker = DependencyTracker::ERBTracker
        DependencyTracker.register_tracker(handler, tracker)
      end

      ActiveSupport.on_load :action_controller do
        ActionController::Base.send :include, CacheDigests::ViewCacheDependency
      end

      config.to_prepare do
        CacheDigests::TemplateDigestor.logger = Rails.logger
      end
    end
  end
end
