require 'cache_digests/test_helper'

class Fragmenter
  include CacheDigests::FragmentHelper
  attr_accessor :virtual_path, :formats, :lookup_context
  def initialize
    @virtual_path = ''
    @formats = [:html]
  end
end

class FragmentHelperTest < MiniTest::Unit::TestCase
  def setup
    # would love some mocha here
    @old_digest = CacheDigests::TemplateDigestor.method(:digest)
    CacheDigests::TemplateDigestor.send(:define_singleton_method, :digest) do |p,f,lc|
      "digest"
    end
  end
  def teardown
    CacheDigests::TemplateDigestor.send(:define_singleton_method, :digest, &@old_digest)
    @fragmenter = nil
  end

  def test_passes_correct_parameters_to_digestor
    CacheDigests::TemplateDigestor.send(:define_singleton_method, :digest) do |p,f,lc|
      extend MiniTest::Assertions
      assert_equal 'path', p
      assert_equal :formats, f
      assert_equal 'lookup context', lc
    end
    fragmenter.virtual_path = 'path'
    fragmenter.formats = ['formats']
    fragmenter.lookup_context = 'lookup context'

    fragmenter.fragment_name_with_digest("key")
  end

  def test_appends_the_key_with_digest
    key_with_digest = fragmenter.fragment_name_with_digest("key")
    assert_equal ['key', 'digest'], key_with_digest
  end

  def test_appends_the_array_key_with_digest
    key_with_digest = fragmenter.fragment_name_with_digest(["key1", "key2"])
    assert_equal ['key1', 'key2', 'digest'], key_with_digest
  end

  private
  def fragmenter
    @fragmenter ||= Fragmenter.new
  end
end
