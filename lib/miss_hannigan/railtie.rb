require 'rails'

module MissHannigan
  class Railtie < Rails::Railtie
    initializer 'miss_hannigan.initialize' do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, MissHannigan
      end
    end
  end
end