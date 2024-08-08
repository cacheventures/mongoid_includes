require 'mongoid'

require 'mongoid/includes'

# add english load path by default
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

Mongoid::Contextual::Mongo.send :prepend, Mongoid::Includes::EagerLoad
Mongoid::Contextual::Memory.send :prepend, Mongoid::Includes::EagerLoad

Mongoid::Criteria.send :prepend, Mongoid::Includes::Criteria
Mongoid::Association::Eager.send :prepend, Mongoid::Includes::Association::Eager
