# frozen_string_literal: true

# =============================================================================
# KnowledgeChunk - CPT Knowledge Base with Vector Search
# =============================================================================
#
# Stores chunks of CPT clinical knowledge with vector embeddings for semantic
# search. This powers the RAG (Retrieval-Augmented Generation) system that
# gives Ross accurate CPT information when responding to users.
#
# Each chunk contains:
# - content: The actual text (typically a few paragraphs)
# - embedding: A 1536-dimension vector (OpenAI text-embedding-3-small)
# - page_number: Source page reference
# - source_doc: Original document name
#
# Vector Search (via pgvector):
# - has_neighbors provides nearest_neighbors() for semantic similarity search
# - Uses cosine distance (lower = more similar)
# - CptChatService queries this for each user message
#
class KnowledgeChunk < ApplicationRecord
  has_neighbors :embedding

  validates :content, presence: true

  # Scope for finding similar chunks given a pre-computed embedding vector
  scope :search_by_embedding, lambda { |embedding, limit: 5|
    nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(limit)
  }

  # High-level search API: converts text query to embedding, then searches.
  # Returns an empty relation if embedding generation fails.
  def self.search(query, limit: 5)
    embedding = generate_embedding(query)
    return none if embedding.nil?

    search_by_embedding(embedding, limit: limit)
  end

  # Generates a vector embedding for text using the configured embedding model.
  # Returns nil on failure for graceful degradation.
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
