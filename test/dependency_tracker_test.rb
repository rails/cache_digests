require 'cache_digests/test_helper'

class NeckbeardTracker
  def self.call(name, template)
    ["foo/#{name}"]
  end
end

module ActionView
  class Template
    def self.handler_for_extension(extension)
      extension
    end
  end
end

class DependencyTrackerTest < MiniTest::Unit::TestCase
  class FakeTemplate
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
    tracker.remove_tracker(:neckbeard)
  end

  def test_finds_tracker_by_template_handler
    template = FakeTemplate.new("boo/hoo", :neckbeard)
    dependencies = tracker.find_dependencies("boo/hoo", template)
    assert_equal ["foo/boo/hoo"], dependencies
  end

  def test_returns_empty_array_if_no_tracker_registered_for_handler
    template = FakeTemplate.new("boo/hoo", :hater)
    dependencies = tracker.find_dependencies("boo/hoo", template)
    assert_equal [], dependencies
  end

  def test_dependency_of_erb_template_with_number_in_filename
    tracker.register_tracker(:erb, CacheDigests::DependencyTracker::ERBTracker)
    template = FakeTemplate.new("<%# render 'messages/message123' %>", :erb)
    dependencies = tracker.find_dependencies("messages/message123", template)
    assert_equal ["messages/message123"], dependencies
    tracker.remove_tracker(:erb)
  end
end
