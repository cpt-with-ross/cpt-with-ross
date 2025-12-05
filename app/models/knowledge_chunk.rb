# Stores CPT knowledge base content with vector embeddings for semantic search.
# Used by the RAG system to provide Ross with accurate CPT information.
class KnowledgeChunk < ApplicationRecord
  has_neighbors :embedding

  validates :content, presence: true

  # Finds the most semantically similar chunks to the query embedding.
  # Returns up to `limit` chunks ordered by cosine similarity.
  scope :search_by_embedding, lambda { |embedding, limit: 5|
    nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(limit)
  }

  # Searches for relevant knowledge chunks using a text query.
  # Generates an embedding for the query and finds similar chunks.
  def self.search(query, limit: 5)
    embedding = generate_embedding(query)
    return none if embedding.nil?

    search_by_embedding(embedding, limit: limit)
  end

  # Generates an embedding vector for the given text using RubyLLM.
  def self.generate_embedding(text)
    config = Rails.application.config.cpt_chat
    response = RubyLLM.embed(
      text,
      model: config[:embedding_model_id],
      provider: config[:embedding_provider].to_sym
    )
    response.vectors
  rescue StandardError => e
    Rails.logger.error("Embedding generation failed: #{e.message}")
    nil
  end
end
