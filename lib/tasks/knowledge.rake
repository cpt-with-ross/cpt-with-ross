namespace :knowledge do
  desc 'Import vectors from local JSONL file (async via background job)'
  task import: :environment do
    files = Rails.root.glob('storage/knowledge-*.jsonl')
    abort 'No knowledge-*.jsonl files found in storage/' if files.empty?

    puts "Found #{files.count} file(s): #{files.map { |f| File.basename(f) }.join(', ')}"
    puts 'Enqueuing import jobs...'

    files.each do |file_path|
      KnowledgeImportJob.perform_later(file_path.to_s)
      puts "  Enqueued: #{File.basename(file_path)}"
    end

    puts "\nJobs enqueued! Run 'bin/rails solid_queue:start' to process."
  end

  desc 'Import vectors synchronously (for development/testing)'
  task import_sync: :environment do
    require 'json'

    files = Rails.root.glob('storage/knowledge-*.jsonl')
    abort 'No knowledge-*.jsonl files found in storage/' if files.empty?

    puts "Found #{files.count} file(s): #{files.map { |f| File.basename(f) }.join(', ')}"
    puts 'Importing knowledge...'
    count = 0
    files.each do |file_path|
      File.foreach(file_path) do |line|
        record = JSON.parse(line)
        KnowledgeChunk.create!(
          content: record['content'],
          page_number: record['page_number'],
          source_doc: record['source_doc'],
          embedding: record['embedding']
        )
        count += 1
        putc '.'
      end
    end
    puts "\nDone! Imported #{count} knowledge chunks."
  end

  desc 'Clear all knowledge chunks'
  task clear: :environment do
    count = KnowledgeChunk.count
    KnowledgeChunk.delete_all
    puts "Deleted #{count} knowledge chunks."
  end
end
