Mongoid::Includes
=====================

[![Gem Version](https://badge.fury.io/rb/mongoid_includes.svg)](https://rubygems.org/gems/mongoid_includes)
[![Build Status](https://github.com/cacheventures/mongoid_includes/workflows/CI/badge.svg)](https://github.com/cacheventures/mongoid_includes/actions)

`Mongoid::Includes` improves eager loading in Mongoid, supporting polymorphic associations, and nested eager loading.

### Usage

```ruby
Album.includes(:songs).includes(:musicians, from: :band)

Band.includes(:albums, with: ->(albums) { albums.gt(release: 1970) })

# The library supports nested eager loading using :from for terseness,
# but you can manually include nested associations using the :with option.
released_only = ->(albums) { albums.where(released: true) }
Musician.includes(:band, with: ->(bands) { bands.limit(2).includes(:albums, with: released_only) })
```

### Pro Tip
Since you can modify the queries for the associations, you can use `only` and make your queries even faster:
```ruby
Band.includes :musicians, with: ->(musicians) { musicians.only(:id, :name) }
```

## Advantages

* [Avoid N+1 queries](http://maximomussini.com/posts/mongoid-n+1/) and get better performance.
* No boilerplate code is required.
* Modify the queries for related documents at will.

## Installation

Add this line to your application's Gemfile and run `bundle install`:

```ruby
  gem 'mongoid_includes'
```

Or install it yourself running:

```sh
gem install mongoid_includes
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
