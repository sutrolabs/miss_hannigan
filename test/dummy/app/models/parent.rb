class Parent < ApplicationRecord
  has_many :normal_children, dependent: :delete_all
  has_many :children, dependent: :nullify_then_purge

  has_one :singleton_child_normal, dependent: :destroy
  has_one :singleton_child_orphan, dependent: :nullify_then_purge
end
