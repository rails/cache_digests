require 'cache_digests/test_helper'

class NeckbeardTracker
  def self.call(name, template)
    ["foo/#{name}"]
  end
end

class DependencyTrackerTest < MiniTest::Unit::TestCase
  class FixtureTemplate
    attr_reader :source, :handler

    def initialize(source, handler)
      @source, @handler = source, handler
    end
  end

  def setup
    CacheDigests::DependencyTracker.register_tracker(:neckbeard, NeckbeardTracker)
  end

  def teardown
    CacheDigests::DependencyTracker.unregister_tracker(:neckbeard)
  end

  def test_finds_tracker_by_template_handler
    name = "boo/hoo"
    template = FixtureTemplate.new("whatevs", :neckbeard)
    dependencies = CacheDigests::DependencyTracker.find_dependencies(name, template)
    assert_equal ["foo/boo/hoo"], dependencies
  end
end
