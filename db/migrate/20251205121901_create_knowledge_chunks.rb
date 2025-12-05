class CreateKnowledgeChunks < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_chunks do |t|
      t.text :content, null: false
      t.integer :page_number
      t.string :source_doc

      t.timestamps
    end

    add_column :knowledge_chunks, :embedding, :vector, limit: 768
    add_index :knowledge_chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
