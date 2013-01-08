module CacheDigests
  class Engine < ::Rails::Engine
    initializer 'cache_digests' do |app|
      require 'cache_digests'

      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, CacheDigests::FragmentHelper
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
