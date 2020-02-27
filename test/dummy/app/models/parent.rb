class Parent < ApplicationRecord
  has_many :normal_children, dependent: :delete_all
  has_many :children, dependent: :nullify_then_purge
  
end
