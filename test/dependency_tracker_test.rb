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

  def tracker
    CacheDigests::DependencyTracker
  end

  def setup
    tracker.register_tracker(:neckbeard, NeckbeardTracker)
  end

  def teardown
    tracker.unregister_tracker(:neckbeard)
  end

  def test_finds_tracker_by_template_handler
    template = FixtureTemplate.new("boo/hoo", :neckbeard)
    dependencies = tracker.find_dependencies("boo/hoo", template)
    assert_equal ["foo/boo/hoo"], dependencies
  end
end
