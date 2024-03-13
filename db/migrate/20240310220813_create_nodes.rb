class CreateNodes < ActiveRecord::Migration[7.0]
  def change
    create_table :nodes do |t|
      t.belongs_to :parent_node
      t.belongs_to :edge_node
      t.json :node_ids
      t.integer :depth

      t.timestamps
    end
  end
end
