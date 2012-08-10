require 'cache_digests/test_helper'
require 'fileutils'

class FixtureTemplate
  attr_reader :source
  
  def initialize(template_path)
    @source = File.read(template_path)
  end
end

class FixtureFinder
  FIXTURES_DIR = "#{File.dirname(__FILE___)}/fixtures"
  TMP_DIR      = "#{File.dirname(__FILE___)}/tmp"
  
  def find(logical_name, keys, partial, formats)
    FixtureTemplate.new("#{TMP_DIR}/#{partial ? "_" : ""}#{logical_name}.#{formats.first}.erb")
  end
end

class TemplateDigestorTest < MiniTest::Unit::TestCase
  setup do
    FileUtils.cp_r FixtureFinder::FIXTURES_DIR, FixtureFinder::TMP_DIR
  end
  
  teardown do
    FileUtils.rm_r FixtureFinder::TMP_DIR
  end

  def test_digest
    assert_digest_difference("messages/show") do
      change_template("messages/show")
    end
  end


  private
    def assert_digest_difference(template_name)
      previous_digest = digest(template_name)
      yield
      assert_not_equal previous_digest, digest(template_name)
    end
  
    def digest(template_name)
      TemplateDigestor.digest(template_name, :html, FixtureFinder.new)
    end
    
    def change_template(template_name)
      File.open("#{FixtureFinder::TMP_DIR}/#{template_name}.html.erb", "rw") do |f|
        f.write "\nTHIS WAS CHANGED!"
      end
    end
end
