# Miss Hannigan

> Daddy Warbucks : You lock the orphans in the closet.
>
> Miss Hannigan : They love it!

## What?

miss_hannigan provides an alternative (and in some cases, better) way to do cascading deletes/destroys in Rails. With it, you can now define a :dependent has_many behavior of :nullify_then_purge which will quickly and synchronously nullify (orphan) children from their parent, and then asynchronously purge those child records (the orphans) from the database. 

```
class Parent < ApplicationRecord
    has_many :children, dependent: :nullify_then_purge
end
```

## Installation

1. Add `gem 'miss_hannigan'` to your Gemfile.
2. Run `bundle install`.
3. Restart your server
4. Add the new dependent option to your has_many relationships: 

```
has_many :children, dependent: :nullify_then_purge
```

Note: If your `child` has a foreign_key relationship with the `parent`, you'll need to make sure the foreign_key in the `child` allows for nulls. For example, you might have to create migrations like this: 

```
class RemoveNullKeyConstraint < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:children, :parent_id, true)
  end
end
```

miss_hannigan will raise an error if the foreign_key isn't configured appropriately. 

miss_hannigan also assumes you're using ActiveJob with an active queue system in place - that's how orphans get asynchronously destroyed after all. 

## Why?

Whether you are a Rails expert or just getting started with the framework, you've most likely had to make smart choices on how cascading deletes work in your system. And often in large systems, you're forced with a compromise...

To quickly catch beginners up, Rails has some great tooling to deal with parent-child relationships using has_many: 

```
class Parent < ApplicationRecord
    has_many :children
end
```

By default, what happens to `children` when you delete an instance of Parent? Nothing. Children just sit tight or in our more typical vernacular, they're orphaned. 

Normally, you consider two options then: destroy the children, or delete the children. 

### dependent: :destroy

Destroying the children is ideal. You do that by setting `dependent: :destroy` on the has_many relationship. Like so: 

```
class Parent ApplicationRecord
    has_many :children, dependent: :destroy
end
```

Rails, when attempting to destroy an instance of the Parent, will also iteratively go through each child of the parent calling destroy on the child. The benefit of this is that any callbacks and validation on those children are given their day in the sun. If you're using a foreign_key constraint between Parent -> Child, this path will also keep your DB happy. (The children are deleted first, then the parent, avoiding the DB complaining about a foreign key being invalid.)

But the main drawback is that destroying a ton of children can be time consuming, especially if those children have their own children (and those have more children, etc.). So time consuming that you simply can't have a user wait that long do even do a delete. And with some hosting platforms, the deletes won't even work as you'll face Timeout errors instead. 

So, many of us reach for the much faster option of using a `:delete_all ` dependency. 

### dependent: :delete_all

Going this route, Rails will delete all children of a parent in a single SQL call without going through the Rails instantiations and callbacks.

```
class Parent ApplicationRecord
    has_many :children, dependent: :delete_all
end
```

However, `:delete` has plenty of problems because it doesn't go through the typical Rails destroy. 

For example, you can't automatically do any post-destroy cleanup (e.g. 3rd party API calls) when those children are destroyed.

And you can't use this approach if you are using foreign key constraints in your DB: 

![](https://github.com/sutrolabs/miss_hannigan/blob/master/foreign_key_error_example.png?raw=true)

Another catch is that if you have a Parent -> Child -> Grandchild relationship, and it uses `dependent: :delete_all` down the tree, destroying a Parent, will stop with deleting the Children. Grandchildren won't even get deleted/destroyed. 

------------

Here at Census this became a problem. We have quite a lot of children of parent objects. And children have children have children... We had users experiencing timeouts during deletions. 

Well, we can't reach for dependent: :delete_all since we have a multiple layered hierarchy of objects that all need destroying. We also have foreign_key constraints we'd like to keep using. 

So what do we do if neither of these approaches work for us? 

We use an "orphan then later purge" approach. Which has some of the best of both :destroy and :delete_all worlds. 

dependent has a nifty but less often mentioned option of :nullify. 

```
class Parent < ApplicationRecord
    has_many :children, dependent: :nullify
end
```

Using :nullify will simply issue a single UPDATE statement setting children's parent_id to NULL. Which is super fast. 

This sets up a bunch of orphaned children now that can easily be cleaned up in an asynchronous purge. 

And now because we're destroying Children here, the normal callbacks are run also allowing Rails to cleanup and destroy GrandChildren. 

Fast AND thorough. 

So we wrapped that pattern together into miss_hannigan: 

```
class Parent < ApplicationRecord
    has_many :children, dependent: :nullify_then_purge
end
```

## Alternatives 

It's worth noting there are other strategies like allowing your DB handle its own cascading deletes. For example, adding foreign keys on a Postgres DB from a Rails migration like so: 

```
add_foreign_key "children", "parents", on_delete: :cascade
```

Doing that will have Postgres automatically delete children rows when a parent is deleted. But that removes itself from Rails-land where we have other cleanup hooks and tooling we'd like to keep running. 

Another alternative would be to use a pattern like acts_as_paranoid to "soft delete" a parent record and later destroy it asynchronously. 


Feedback
--------
[Source code available on Github](https://github.com/sutrolabs/miss_hannigan). Feedback and pull requests are greatly appreciated. Let us know if we can improve this.


From
-----------
:wave: The folks at [Census](http://getcensus.com) originally put this together. Have data? We'll sync your data warehouse with your CRM and the customer success apps critical to your team. 
