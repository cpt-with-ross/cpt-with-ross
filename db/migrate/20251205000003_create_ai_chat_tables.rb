# frozen_string_literal: true

class CreateAiChatTables < ActiveRecord::Migration[7.1]
  def change
    # Models table - LLM configurations
    create_table :models do |t|
      t.string :model_id, null: false
      t.string :name, null: false
      t.string :provider, null: false
      t.string :family
      t.datetime :model_created_at
      t.integer :context_window
      t.integer :max_output_tokens
      t.date :knowledge_cutoff

      t.jsonb :modalities, default: {}
      t.jsonb :capabilities, default: []
      t.jsonb :pricing, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps

      t.index %i[provider model_id], unique: true
      t.index :provider
      t.index :family
      t.index :capabilities, using: :gin
      t.index :modalities, using: :gin
    end

    # Chats table - conversation containers
    create_table :chats do |t|
      t.references :model, foreign_key: true

      t.timestamps
    end

    # Messages table - individual messages
    create_table :messages do |t|
      t.string :role, null: false
      t.text :content
      t.json :content_raw
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :cached_tokens
      t.integer :cache_creation_tokens
      t.references :chat, null: false, foreign_key: true
      t.references :model, foreign_key: true

      t.timestamps
    end

    add_index :messages, :role

    # Tool calls table - function calls made by the AI
    create_table :tool_calls do |t|
      t.string :tool_call_id, null: false
      t.string :name, null: false
      t.jsonb :arguments, default: {}
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end

    add_index :tool_calls, :tool_call_id, unique: true
    add_index :tool_calls, :name

    # Add tool_call reference to messages (for tool responses)
    add_reference :messages, :tool_call, foreign_key: true

    # Load models from JSON
    reversible do |dir|
      dir.up do
        say_with_time 'Loading models from models.json' do
          RubyLLM.models.load_from_json!
          Model.save_to_database
        end
      end
    end
  end
end
