module CacheDigests
  class Railtie < ::Rails::Railtie
    initializer 'cache_digests' do |app|
      require 'cache_digests'

      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, CacheDigests::FragmentHelper
      end
    end
  end
end
