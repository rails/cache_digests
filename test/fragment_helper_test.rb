require 'cache_digests/test_helper'

class Fragmenter
  include CacheDigests::FragmentHelper
  attr_accessor :virtual_path, :formats, :lookup_context
  def initialize
    @virtual_path = ''
    @formats = [:html]
  end
end

class BaseFragmenter
  attr_accessor :virtual_path, :formats, :lookup_context, :view_cache_dependencies
  def initialize
    @virtual_path = ''
    @formats = [:html]
    @view_cache_dependencies = []
  end

  private
    # Give a base implementation of fragment_for so super calls from
    # ChildFragmenter have a method to delegate to.
    def fragment_for(key,opts=nil,&blk)
      key
    end
end

class ChildFragmenter < BaseFragmenter
  include CacheDigests::FragmentHelper
end

class FragmentHelperTest < MiniTest::Unit::TestCase
  def setup
    # would love some mocha here
    @old_digest = CacheDigests::TemplateDigestor.method(:digest)
    CacheDigests::TemplateDigestor.send(:define_singleton_method, :digest) do |p,f,lc,o={}|
      "digest"
    end
  end
  def teardown
    CacheDigests::TemplateDigestor.send(:define_singleton_method, :digest, &@old_digest)
    @fragmenter = nil
  end

  def test_passes_correct_parameters_to_digestor
    CacheDigests::TemplateDigestor.send(:define_singleton_method, :digest) do |p,f,lc,o={}|
      extend MiniTest::Assertions
      assert_equal 'path', p
      assert_equal :formats, f
      assert_equal 'lookup context', lc
      assert_equal({dependencies:["foo"]}, o)
    end
    fragmenter.virtual_path = 'path'
    fragmenter.formats = ['formats']
    fragmenter.lookup_context = 'lookup context'

    fragmenter.fragment_name_with_digest("key", ["foo"])
  end

  def test_appends_the_key_with_digest
    key_with_digest = fragmenter.fragment_name_with_digest("key")
    assert_equal ['key', 'digest'], key_with_digest
  end

  def test_appends_the_array_key_with_digest
    key_with_digest = fragmenter.fragment_name_with_digest(["key1", "key2"])
    assert_equal ['key1', 'key2', 'digest'], key_with_digest
  end

  def test_digest_skipped_when_opted_out
    key = child_fragmenter.send(:fragment_for, 'key1', {skip_digest: true})
    # 'key1' key derived from super call to BaseFragmenter above
    assert_equal 'key1', key
  end

  def test_digest_skipped_when_v_number_keyed
    key = child_fragmenter.send(:fragment_for, ['v1','key1'])
    assert_equal ['v1','key1'], key
  end

  def test_digest_not_skipped_otherwise
    key_with_digest = child_fragmenter.send(:fragment_for, 'key1', {skip_digest: false})
    assert_equal ['key1','digest'], key_with_digest
  end

  private
  def fragmenter
    @fragmenter ||= Fragmenter.new
  end

  def child_fragmenter
    @child_fragmenter ||= ChildFragmenter.new
  end
end
