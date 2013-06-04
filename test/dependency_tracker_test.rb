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

class FakeTemplate
  attr_reader :source, :handler

  def initialize(source, handler)
    @source, @handler = source, handler
  end
end

class DependencyTrackerTest < MiniTest::Unit::TestCase
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
end

class ERBTrackerTest < MiniTest::Unit::TestCase
  def make_tracker(name, template)
    CacheDigests::DependencyTracker::ERBTracker.new(name, template)
  end

  def test_dependency_of_erb_template_with_number_in_filename
    template = FakeTemplate.new("<%# render 'messages/message123' %>", :erb)
    tracker = make_tracker('messages/_message123', template)

    assert_equal ["messages/message123"], tracker.dependencies
  end

  def test_finds_dependency_in_correct_directory
    template = FakeTemplate.new("<%# render(message.topic) %>", :erb)
    tracker = make_tracker('messages/_message', template)

    assert_equal ["topics/topic"], tracker.dependencies
  end

  def test_finds_dependency_in_correct_directory_with_underscore
    template = FakeTemplate.new("<%# render(message_type.messages) %>", :erb)
    tracker = make_tracker('message_types/_message_type', template)

    assert_equal ["messages/message"], tracker.dependencies
  end
end

