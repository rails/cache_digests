require 'cache_digests/test_helper'
require 'fileutils'

module ActionView
  class MissingTemplate < StandardError
  end
end

class FixtureTemplate
  attr_reader :source
  
  def initialize(template_path)
    @source = File.read(template_path)
  rescue Errno::ENOENT
    raise ActionView::MissingTemplate
  end
end

class FixtureFinder
  FIXTURES_DIR = "#{File.dirname(__FILE__)}/fixtures"
  TMP_DIR      = "#{File.dirname(__FILE__)}/tmp"
  
  def find(logical_name, keys, partial, options)
    FixtureTemplate.new("#{TMP_DIR}/#{partial ? logical_name.gsub(%r|/([^/]+)$|, '/_\1') : logical_name}.#{options[:formats].first}.erb")
  end
end

class TemplateDigestorTest < MiniTest::Unit::TestCase
  def setup
    FileUtils.cp_r FixtureFinder::FIXTURES_DIR, FixtureFinder::TMP_DIR
  end
  
  def teardown
    FileUtils.rm_r FixtureFinder::TMP_DIR
    CacheDigests::TemplateDigestor.cache.clear
  end

  def test_top_level_change_reflected
    assert_digest_difference("messages/show") do
      change_template("messages/show")
    end
  end

  def test_explicit_dependency
    assert_digest_difference("messages/show") do
      change_template("messages/_message")
    end
  end

  def test_second_level_dependency
    assert_digest_difference("messages/show") do
      change_template("comments/_comments")
    end
  end

  def test_second_level_dependency_within_same_directory
    assert_digest_difference("messages/show") do
      change_template("messages/_header")
    end
  end

  def test_third_level_dependency
    assert_digest_difference("messages/show") do
      change_template("comments/_comment")
    end
  end
  
  def test_directory_depth_dependency
    assert_digest_difference("level/below/index") do
      change_template("level/below/_header")
    end
  end

  def test_logging_of_missing_template
    assert_logged "Couldn't find template for digesting: messages/something_missing.html" do
      digest("messages/show")
    end
  end

  def test_nested_template_directory
    assert_digest_difference("messages/show") do
      change_template("messages/actions/_move")
    end
  end
  
  def test_dont_generate_a_digest_for_missing_templates
    assert_equal '', digest("nothing/there")
  end

  def test_collection_dependency
    assert_digest_difference("messages/index") do
      change_template("messages/_message")
    end

    assert_digest_difference("messages/index") do
      change_template("events/_event")
    end
  end
  
  def test_collection_derived_from_record_dependency
    assert_digest_difference("messages/show") do
      change_template("events/_event")
    end
  end


  private
    def assert_logged(message)
      log = StringIO.new
      CacheDigests::TemplateDigestor.logger = Logger.new(log)

      yield
      
      log.rewind
      assert_match message, log.read
      
      CacheDigests::TemplateDigestor.logger = nil
    end

    def assert_digest_difference(template_name)
      previous_digest = digest(template_name)
      CacheDigests::TemplateDigestor.cache.clear

      yield

      assert previous_digest != digest(template_name), "digest didn't change"
      CacheDigests::TemplateDigestor.cache.clear
    end
  
    def digest(template_name)
      CacheDigests::TemplateDigestor.digest(template_name, :html, FixtureFinder.new)
    end
    
    def change_template(template_name)
      File.open("#{FixtureFinder::TMP_DIR}/#{template_name}.html.erb", "w") do |f|
        f.write "\nTHIS WAS CHANGED!"
      end
    end
end
