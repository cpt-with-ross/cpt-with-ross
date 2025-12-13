# frozen_string_literal: true

# =============================================================================
# KnowledgeImportJob - CPT Knowledge Base Population
# =============================================================================
#
# Imports pre-processed CPT clinical knowledge from JSONL files into the
# KnowledgeChunk table for RAG (Retrieval-Augmented Generation) queries.
#
# JSONL Format Expected:
# Each line is a JSON object with: content, page_number, source_doc, embedding
# Embeddings should be pre-computed vectors (768 dimensions for
# Google text-embedding-004 via Vertex AI).
#
# Performance:
# Uses batch inserts (insert_all) to efficiently handle large knowledge bases.
# Runs in 'background' queue to avoid blocking user-facing operations.
#
# Usage:
#   KnowledgeImportJob.perform_later('/path/to/cpt_manual.jsonl')
#
class KnowledgeImportJob < ApplicationJob
  queue_as :background

  BATCH_SIZE = 100 # Records per batch insert - balances memory vs DB round trips

  def perform(file_path)
    unless File.exist?(file_path)
      Rails.logger.error("KnowledgeImportJob: File not found - #{file_path}")
      return
    end

    Rails.logger.info("KnowledgeImportJob: Starting import from #{File.basename(file_path)}")

    records = []
    count = 0

    # Stream file line-by-line to handle large files without memory issues
    File.foreach(file_path) do |line|
      record = JSON.parse(line)
      records << {
        content: record['content'],
        page_number: record['page_number'],
        source_doc: record['source_doc'],
        embedding: record['embedding'],
        created_at: Time.current,
        updated_at: Time.current
      }

      # Flush batch when threshold reached
      if records.size >= BATCH_SIZE
        KnowledgeChunk.insert_all(records) # rubocop:disable Rails/SkipsModelValidations
        count += records.size
        records.clear
        Rails.logger.info("KnowledgeImportJob: Imported #{count} chunks...")
      end
    end

    # Insert any remaining records that didn't fill a complete batch
    if records.any?
      KnowledgeChunk.insert_all(records) # rubocop:disable Rails/SkipsModelValidations
      count += records.size
    end

    Rails.logger.info("KnowledgeImportJob: Completed! Imported #{count} chunks from #{File.basename(file_path)}")
  rescue JSON::ParserError => e
    Rails.logger.error("KnowledgeImportJob: JSON parse error - #{e.message}")
    raise # Re-raise to trigger job retry mechanism
  end
end
