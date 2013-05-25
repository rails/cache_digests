Cache Digests
=============

Russian-doll caching schemes are hard to maintain when nested templates are updated. The manual approach works something like this:

```HTML+ERB
# app/views/projects/show.html.erb
<% cache [ "v1", project ] do %>
  <h1>All documents</h1>
  <%= render project.documents %>

  <h1>All todolists</h1>
  <%= render project.todolists %>
<% end %>


# app/views/documents/_document.html.erb
<% cache [ "v1", document ] do %>
  My document: <%= document.name %>

  <%= render document.comments %>
<% end %>


# app/views/todolists/_todolist.html.erb
<% cache [ "v1", todolist ] do %>
  My todolist: <%= todolist.name %>

  <%= render document.comments %>
<% end %>

# app/views/comments/_comment.html.erb
<% cache [ "v1", comment ] do %>
  My comment: <%= comment.body %>
<% end %>
```

Now if I change app/views/comments/_comment.html.erb, I'll be forced to manually track down and bump the other three templates. And there's no visual reference in app/views/projects/show.html.erb that this template even depends on the comment template.

That puts a serious cramp in our rocking caching style.

Enter Cache Digests: With this plugin, all calls to #cache in the view will automatically append a digest of that template _and_ all of its dependencies! So you no longer need to manually increment versions in the specific templates you're working on or care about what other templates are depending on the change you make.

Our code from above can just look like:

```HTML+ERB
# app/views/projects/show.html.erb
<% cache project do %>
...

# app/views/documents/_document.html.erb
<% cache document do %>
...

# app/views/todolists/_todolist.html.erb
<% cache todolist do %>
...

# app/views/comments/_comment.html.erb
<% cache comment do %>
...
```

The caching key for app/views/projects/show.html.erb will be something like `views/projects/605816632-20120810191209/d9fb66b120b61f46707c67ab41d93cb2`. That last bit is a MD5 of the template file itself and all of its dependencies. It'll change if you change either the template or any of the dependencies, and thus allow the cache to expire automatically.

You can use these handy rake tasks to see how deep the rabbit hole goes:

```
$ rake cache_digests:dependencies TEMPLATE=projects/show
[
  "documents/document",
  "todolists/todolist"
]


$ rake cache_digests:nested_dependencies TEMPLATE=projects/show
[
  {
    "documents/document": [
      "comments/comment"
    ]
  },
  {
    "todolists/todolist": [
      "comments/comment"
    ]
  }
]
```
Note: this rake task doesn't differentiate between dependencies that are cached and dependencies that aren't - it is meant to show you all the dependencies of your view that cache_digests is able to derive.

Recomputing digests after updating a template
---------------------------------------------

If your application's environment has caching enabled with `config.action_view.cache_template_loading` (e.g. production) then template digests are only computed once and saved until the application is restarted. Any updates to a template will require an application restart in order for the template source and digest changes to be reflected. If `config.action_view.cache_template_loading` is unset then it is set to the value of `config.cache_classes` by default.

For environments that do not enable `config.action_view.cache_template_loading` (e.g. development) the default `CacheDigests::TemplateDigestor.cache` store is set to `ActiveSupport::Cache::NullStore.new`. This cache implementation doesn't actually store anything which forces template digests to recompute on every request. This is useful for cases where you want to test fragment caching (by enabling `config.action_controller.perform_caching`) or add template digests to your ETags with [rails/etagger](https://github.com/rails/etagger) but still allow templates and digests to reload any time a template is changed.

Implicit dependencies
---------------------

Most template dependencies can be derived from calls to render in the template itself. Here are some examples of render calls that Cache Digests knows how to decode:

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render 'comments/comments'
render('comments/comments')

render "header" => render("comments/header")

render(@topic)         => render("topics/topic")
render(topics)         => render("topics/topic")
render(message.topics) => render("topics/topic")
```

It's not possible to derive all render calls like that, though. Here are a few examples of things that can't be derived:

```ruby
render group_of_attachments
render @project.documents.where(published: true).order('created_at')
```

You will have to rewrite those to the explicit form:

```ruby
render partial: 'attachments/attachment', collection: group_of_attachments
render partial: 'documents/document', collection: @project.documents.where(published: true).order('created_at')
```

Explicit dependencies
---------------------

Some times you'll have template dependencies that can't be derived at all. This is typically the case when you have template rendering that happens in helpers. Here's an example:

```HTML+ERB
<%= render_sortable_todolists @project.todolists %>
```

You'll need to use a special comment format to call those out:

```HTML+ERB
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

The pattern used to match these is `/# Template Dependency: ([^ ]+)/`, so it's important that you type it out just so. You can only declare one template dependency per line.
