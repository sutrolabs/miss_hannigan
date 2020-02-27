class CreateNormalChildren < ActiveRecord::Migration[6.0]
  def change
    create_table :normal_children do |t|
      t.references :parent, null: false, foreign_key: true

      t.timestamps
    end
  end
end
