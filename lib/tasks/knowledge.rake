# lib/tasks/knowledge.rake
namespace :knowledge do
  desc 'Import vectors from local JSONL export'
  task import: :environment do
    # Requires standard Ruby JSON library
    require 'json'

    # Define the directory where you placed your downloaded JSONL files
    data_dir = Rails.root.join('db/knowledge_data')

    puts "Starting Import from local directory: #{data_dir}"

    Dir.glob(data_dir.join('knowledge-*.jsonl')).each do |file_path|
      file_name = File.basename(file_path)
      puts "Processing #{file_name}..."

      # Load the entire file into memory as a string
      jsonl_string = File.read(file_path)

      # Process each line as a separate JSON record (JSONL format)
      jsonl_string.each_line do |line|
        next if line.blank?

        # Parse the JSON record for that specific line
        record = JSON.parse(line)

        # Insert record into the database
        KnowledgeChunk.create!(
          content: record['content'],
          page_number: record['page_number'].to_i,
          source_uri: file_name,
          embedding: record['embedding']
        )
      end
    end

    puts 'Import Complete!'
  end
end
