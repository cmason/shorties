class CreateUrls < ActiveRecord::Migration
  def change
    create_table :urls do |t|
      t.string :long_url, :length => 2048
      t.timestamps
    end
  end
end
