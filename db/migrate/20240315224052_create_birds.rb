class CreateBirds < ActiveRecord::Migration[7.0]
  def change
    create_table :birds do |t|
      t.belongs_to :node
      t.timestamps
    end
  end
end
