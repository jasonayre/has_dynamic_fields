require "acts_as_dynamic"
require "rails"

module ActsAsDynamic
  class Railtie < Rails::Railtie
    initializer 'acts_as_dynamic.ar_extensions' do |app|
      ActiveRecord::Base.extend ActsAsDynamic::Base
    end
  end
end