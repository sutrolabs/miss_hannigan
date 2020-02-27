require 'test_helper'
require 'byebug'

migration_file_name = Dir[Rails.root.join('../dummy/db/migrate/*_remove_null_key_constraint.rb')].first
require migration_file_name

class MissHannigan::Test < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "truth" do
    assert_kind_of Module, MissHannigan
  end

  test "raises error if not nullable foreign key" do
    migration = RemoveNullKeyConstraint.new
    migration.migrate(:down)
    assert_raise do 

      Child.reset_column_information

      Object.send(:remove_const, :Child)
      Object.send(:remove_const, :Parent)
      
      load Rails.root.join('../dummy/app/models/child.rb')
      load Rails.root.join('../dummy/app/models/parent.rb')
    
      Parent.all
    end
  end

  test "no error if nullable foreign key" do
    Parent.all
  end

  test "has_many works like normal with dependent delete" do 
    parent = nil 

    assert_difference "NormalChild.count", 2 do 
      parent = Parent.create(name: "parent")
      normal_child = parent.normal_children.create

      second_parent = Parent.create(name: "second")
      second_normal_child = second_parent.normal_children.create
    end

    assert_difference 'NormalChild.count', -1 do
      parent.destroy
    end
  end

  test "has_many nullify_then_purge nullifies children first" do 
    parent = nil 

    assert_difference "Child.count", 1 do 
      parent = Parent.create(name: "parent")
      normal_child = parent.children.create
    end

    assert_difference 'Child.where(parent: nil).count', 1 do 
      assert_difference 'Child.count', 0 do
        parent.destroy
      end
    end
  end

  test "has_many nullify_then_purge purges nullified children" do 
    parent = Parent.create(name: "parent")
    normal_child = parent.children.create

    assert_difference 'Child.count', -1 do
      perform_enqueued_jobs do
        parent.destroy
      end
      assert_performed_jobs 1
    end
  end
end
