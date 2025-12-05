# Background job for importing knowledge chunks from JSONL files.
# Processes files asynchronously with batch inserts for efficiency.
class KnowledgeImportJob < ApplicationJob
  queue_as :background

  BATCH_SIZE = 100

  def perform(file_path)
    unless File.exist?(file_path)
      Rails.logger.error("KnowledgeImportJob: File not found - #{file_path}")
      return
    end

    Rails.logger.info("KnowledgeImportJob: Starting import from #{File.basename(file_path)}")

    records = []
    count = 0

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

      if records.size >= BATCH_SIZE
        KnowledgeChunk.insert_all(records) # rubocop:disable Rails/SkipsModelValidations
        count += records.size
        records.clear
        Rails.logger.info("KnowledgeImportJob: Imported #{count} chunks...")
      end
    end

    # Insert remaining records
    if records.any?
      KnowledgeChunk.insert_all(records) # rubocop:disable Rails/SkipsModelValidations
      count += records.size
    end

    Rails.logger.info("KnowledgeImportJob: Completed! Imported #{count} chunks from #{File.basename(file_path)}")
  rescue JSON::ParserError => e
    Rails.logger.error("KnowledgeImportJob: JSON parse error - #{e.message}")
    raise
  end
end
