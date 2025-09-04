require 'simplecov'
SimpleCov.start

require 'rspec/given'
require 'pry'
require 'mongoid_includes'

# Load Support files
Dir['./spec/support/**/*.rb'].map do |f|
  require f
end

I18n.config.enforce_available_locales = false

# These are used when creating any connection in the test suite.
HOST = ENV['MONGOID_SPEC_HOST'] ||= 'localhost'
PORT = ENV['MONGOID_SPEC_PORT'] ||= '27017'
DATABASE = ENV['MONGOID_DATABASE'] ||= 'mongoid_test'

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.load_configuration(
    clients: {
      default: {
        database: DATABASE,
        hosts: [ "#{HOST}:#{PORT.to_i}" ],
        options: {
          max_pool_size: 1,
        }
      }
    },
    sessions: {
      default: {
        database: DATABASE,
        hosts: [ "#{HOST}:#{PORT.to_i}" ]
      }
    }
  )
end

# Logging to the console is useful for debugging queries.
Mongo::Logger.logger = Logger.new('./spec/mongo.log')

def log_mongo_to_console
  Mongo::Logger.logger = Logger.new($stdout)
end

RSpec.configure do |config|
  config.include Mongoid::SpecHelpers
  config.raise_errors_for_deprecations!

  # Drop all collections and clear the identity map before each spec.
  config.before(:each) do
    Mongoid.purge!
  end
end

Time.zone = 'UTC'
