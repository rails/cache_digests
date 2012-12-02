require 'cache_digests/test_helper'
require 'fileutils'

class RenderDependencyMatcherTest < MiniTest::Unit::TestCase
  def test_matches_render_partial
    assert_matched "render partial: \"comments/comment\", collection: commentable.comments"
  end

  def test_matches_render_no_partial_double_quote
    assert_matched "render \"comments/comments\""
  end

  def test_matches_render_no_partial_single_quote
    assert_matched "render 'comments/comments'"
  end

  def test_matches_render_no_partial_single_quote_in_parens
    assert_matched "render('comments/comments')"
  end

  def test_matches_render_with_instance_var
    assert_matched "render(@topic)"
  end

  def test_matches_render_with_local_var
    assert_matched "render(topics)"
  end

  def test_misses_string_rendered
    assert_misses "rendered"
  end

  private
    def matcher
      CacheDigests::TemplateDigestor::RENDER_DEPENDENCY
    end

    def assert_matched(str)
      assert str =~ matcher, "Should have matched #{str} but didn't."
    end

    def assert_misses(str)
      assert str !~ matcher, "Matched #{str} but should not have."
    end
end
