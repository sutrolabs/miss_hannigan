require 'test_helper'
require 'byebug'

migration_file_name = Dir[Rails.root.join('../dummy/db/migrate/*_remove_null_key_constraint.rb')].first
require migration_file_name

class MissHannigan::Test < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "truth" do
    assert_kind_of Module, MissHannigan
  end

  # TODO: Having trouble getting this test to play nice with the whole test suite. 
  # test "raises error if not nullable foreign key" do
  #   migration = RemoveNullKeyConstraint.new
  #   migration.migrate(:down)
  #   assert_raise do 

  #     Child.reset_column_information

  #     # Object.send(:remove_const, :Child)
  #     # Object.send(:remove_const, :Parent)
      
  #     load Rails.root.join('../dummy/app/models/child.rb')
  #     load Rails.root.join('../dummy/app/models/parent.rb')
    
  #     Parent.all
  #   end
  # end

  test "no error if nullable foreign key" do
    Parent.all
  end

  test "has_many works like normal with dependent delete" do 
    parent = nil 

    assert_difference "NormalChild.count", 2 do 
      parent = Parent.create(name: "parent")
      parent.normal_children.create

      second_parent = Parent.create(name: "second")
      second_parent.normal_children.create
    end

    assert_difference 'NormalChild.count', -1 do
      parent.destroy
    end
  end

  test "has_many nullify_then_purge nullifies children first" do 
    parent = nil 

    assert_difference "Child.count", 1 do 
      parent = Parent.create(name: "parent")
      parent.children.create
    end

    assert_difference 'Child.where(parent: nil).count', 1 do 
      assert_difference 'Child.count', 0 do
        parent.destroy
      end
    end
  end

  test "has_many nullify_then_purge purges nullified children" do 
    Parent.all

    parent = Parent.create(name: "parent")
    parent.children.create

    assert_difference 'Child.count', -1 do
      assert_performed_jobs 2 do
        parent.destroy
        perform_enqueued_jobs
      end
    end
  end

  test "has_one works like normal with dependent delete" do
    parent = nil

    assert_difference "SingletonChildNormal.count", 2 do
      parent = Parent.create(name: "parent")
      parent.create_singleton_child_normal!

      second_parent = Parent.create(name: "second")
      second_parent.create_singleton_child_normal!
    end

    assert_difference 'SingletonChildNormal.count', -1 do
      parent.destroy
    end
  end

  test "has_one nullify_then_purge nullifies children first" do
    parent = nil

    assert_difference "SingletonChildOrphan.count", 1 do
      parent = Parent.create(name: "parent")
      parent.create_singleton_child_orphan!
    end

    assert_difference 'SingletonChildOrphan.where(parent: nil).count', 1 do
      assert_difference 'SingletonChildOrphan.count', 0 do
        parent.destroy
      end
    end
  end

  test "has_one nullify_then_purge purges nullified children" do
    Parent.all

    parent = Parent.create(name: "parent")
    parent.create_singleton_child_normal!
    parent.create_singleton_child_orphan!

    assert_difference 'SingletonChildNormal.count', -1 do
      assert_difference 'SingletonChildOrphan.count', -1 do
        assert_performed_jobs 2 do
          parent.destroy
          perform_enqueued_jobs
        end
      end
    end
  end
end
