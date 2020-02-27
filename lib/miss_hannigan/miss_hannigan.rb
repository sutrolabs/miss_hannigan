module MissHannigan
  extend ActiveSupport::Concern

  module ClassMethods

    def has_many(name, scope = nil, **options, &extension) 
      nullify_then_purge = false

      if options[:dependent] == :nullify_then_purge
        nullify_then_purge = true
        options[:dependent] = :nullify
      end

      reflection = super

      if nullify_then_purge
        reflection_details = reflection[name.to_s]

        if !reflection_details.klass.columns.find { |c| c.name == reflection_details.foreign_key }.null
          raise "The foreign key must be nullable to support MissHannigan. You should create a migration to: 
            change_column_null :#{name.to_s}, :#{reflection_details.foreign_key}, true"
        end

        after_destroy do |this_object|
          # byebug
          CleanupJob.perform_later(reflection_details.klass.to_s, reflection_details.foreign_key)
        end
      end

      return reflection
    end
  end

  class CleanupJob < ActiveJob::Base
    queue_as :default
    
    def perform(klass_string, parent_foreign_key)
      klass = klass_string.constantize

      klass.where(parent_foreign_key => nil).destroy_all
    end
  end
end
