require "active_storage/service"
require "rspec/common/helpers/active_storage/configurator"

module ActiveStorage
  class Service::Configurator
    prepend ::RSpec::Common::Helpers::ActiveStorage::Configurator
  end
end

