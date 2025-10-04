# Mongoid::Includes

[![Gem Version](https://badge.fury.io/rb/mongoid_includes.svg)](https://rubygems.org/gems/mongoid_includes)
[![Build Status](https://github.com/cacheventures/mongoid_includes/workflows/CI/badge.svg)](https://github.com/cacheventures/mongoid_includes/actions)

`Mongoid::Includes` improves eager loading in Mongoid, supporting polymorphic associations, and nested eager loading.

## Usage

```ruby
Album.includes(:songs).includes(:musicians, from: :band)

Band.includes(:albums, with: ->(albums) { albums.gt(release: 1970) })

# The library supports nested eager loading using :from for terseness,
# but you can manually include nested associations using the :with option.
released_only = ->(albums) { albums.where(released: true) }
Musician.includes(:band, with: ->(bands) { bands.limit(2).includes(:albums, with: released_only) })
```

## Pro Tip

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

Or install it yourself by running:

```sh
gem install mongoid_includes
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Running tests

To run the full test suite locally:

```sh
bundle install
bundle exec rspec
# or use the bundled binary
bin/rspec
```

To run the tests against the Mongoid 8 matrix (this project provides a separate Gemfile at `gemfiles/mongoid8.gemfile`), set `BUNDLE_GEMFILE` to that file before installing or running the suite:

```sh
# install gems for the mongoid8 Gemfile
BUNDLE_GEMFILE=gemfiles/mongoid8.gemfile bundle install

# run the specs using that Gemfile
BUNDLE_GEMFILE=gemfiles/mongoid8.gemfile bundle exec rspec
# or
BUNDLE_GEMFILE=gemfiles/mongoid8.gemfile bundle exec bin/rspec
```

If you only need to run a single spec file while using the alternate Gemfile, pass the path to `rspec` as usual, for example:

```sh
BUNDLE_GEMFILE=gemfiles/mongoid8.gemfile bundle exec rspec spec/mongoid/includes/criteria_spec.rb
```

## Contributing

Contributions are welcome. If you'd like to report a bug, suggest an improvement, or submit a patch, please follow these steps:

1. Fork the repository on GitHub.
2. Create a feature branch from `master` (or from the branch you're targeting):

   ```sh
   git switch -c my-feature-branch
   ```

3. Make your changes. Add or update tests when appropriate.
4. Run the test suite locally to ensure everything passes:

   ```sh
   bundle install
   bundle exec rspec
   ```

5. Commit your changes with a clear message and push your branch to your fork:

   ```sh
   git add -A
   git commit -m "Short, descriptive message"
   git push origin my-feature-branch
   ```

6. Open a Pull Request against the `master` branch of this repository. In your PR description, explain the problem, what you changed, and any notes about compatibility or required steps.
