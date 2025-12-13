# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CPT with Ross is an AI-assisted self-help web application for Cognitive Processing Therapy (CPT) for PTSD. Built with Rails 7.1, PostgreSQL (with pgvector), and Hotwire (Turbo/Stimulus).

**Core Therapy Flow:** The user has experienced a trauma (called an "index event"). This event causes one or more "stuck points" (unhelpful thoughts/beliefs). These can be analyzed via ABC Worksheets (cognitive analysis) or challenged via Alternative Thoughts (cognitive restructuring).

**Key Features:**
- RAG-powered AI chat assistant ("Ross") with CPT clinical knowledge
- Real-time streaming responses via ActionCable
- Text-to-speech with word-level highlighting
- PDF export and email sharing of worksheets

## Environment Variables

See `.env.example` for full list. Key variables:

**Required (Development & Production):**
- `GOOGLE_CLOUD_PROJECT` - GCP project ID for Vertex AI and TTS
- `GOOGLE_CLOUD_LOCATION` - GCP region (default: `us-central1`)
- `RESEND_API_KEY` - Email service API key for PDF sharing

**Production Only:**
- `DATABASE_URL` - PostgreSQL connection string
- `RAILS_MASTER_KEY` - For encrypted credentials
- `SECRET_KEY_BASE` - Session encryption
- `JOB_CONCURRENCY` - Background job worker count

## Common Commands

```bash
# Development (runs web server + background jobs via overmind/foreman)
bin/dev

# Run components separately
bin/rails server                   # Web server only
bin/jobs                           # Background jobs only (Solid Queue)

# Setup
bin/setup                          # Full environment setup (deps, DB, seeds)
bin/rails db:prepare               # Create/migrate database

# Database
bin/rails db:migrate               # Run migrations
bin/rails db:seed                  # Seed database
bin/rails db:reset                 # Drop, recreate, migrate, seed

# Knowledge Base (RAG)
bin/rails knowledge:import         # Import CPT knowledge (async via job)
bin/rails knowledge:import_sync    # Import synchronously (dev/test)
bin/rails knowledge:clear          # Clear all knowledge chunks

# LLM Models
bin/rails ruby_llm:load_models     # Load LLM model configs from models.json

# Testing
bin/rails test                     # Run all tests
bin/rails test test/models/        # Run all model tests
bin/rails test path/to/test.rb:42  # Run specific test at line

# Linting
npm run lint:check                 # Check all (Ruby + JS + ERB)
npm run lint:fix                   # Auto-fix all
bundle exec rubocop -A             # Ruby auto-fix only
```

## Architecture

### Domain Model Hierarchy

The core CPT therapy workflow follows this hierarchical structure:

```
User (Devise auth)
└── IndexEvent (traumatic event being processed)
    ├── Baseline (1:1, auto-created with IndexEvent)
    └── StuckPoint[] (negative thoughts/beliefs)
        ├── AbcWorksheet[] (A-B-C cognitive worksheets)
        └── AlternativeThought[] (balanced thought challenges)
```

Additional models:
- `Chat` - AI conversation session (one per user, persistent)
- `Message` - Individual chat messages with streaming support
- `KnowledgeChunk` - CPT clinical knowledge with vector embeddings

### AI Chat System & RAG

Uses `ruby_llm` gem with Google Vertex AI:
- **LLM:** Gemini 2.5 Flash (`gemini-2.5-flash`)
- **Embeddings:** `text-embedding-004` (768 dimensions)
- **Configuration:** `config/initializers/ruby_llm.rb`

**RAG Pipeline (`app/services/cpt_chat_service.rb`):**
1. Embeds user query via Vertex AI
2. Searches `KnowledgeChunk` using pgvector (cosine distance)
3. Retrieves user's stuck points and current focus context
4. Builds dynamic system prompt with clinical guidelines
5. Streams response via ActionCable

**Focus Context:** Controllers set `@focus_context` to track what the user is viewing (baseline, worksheet, etc.). This context is passed to the AI for personalized responses.

**Relevance Thresholds:**
- Primary: 0.35 cosine distance
- Fallback: 0.5 (if no primary matches found)

### Background Jobs

Uses **Solid Queue** (database-backed, no Redis required).

| Job | Queue | Purpose |
|-----|-------|---------|
| `ChatResponseJob` | critical | LLM invocation with real-time streaming |
| `TextToSpeechJob` | background | Google Cloud TTS with word-level timepoints |
| `KnowledgeImportJob` | background | Batch import of CPT knowledge embeddings |
| `DeleteChatMessagesJob` | background | Async chat history clearing |

**Queue Config (`config/queue.yml`):**
- `critical`: 0.1s polling, 3-5 threads (low latency for chat)
- `background`: 0.5-1s polling, 2-3 threads

### External Services

**Google Cloud Vertex AI:**
- LLM inference and text embeddings
- Auth: Application Default Credentials (ADC)
- Config: `config/initializers/ruby_llm.rb`

**Google Cloud Text-to-Speech:**
- Voice: `en-US-Neural2-J` (male, Neural2 quality)
- Output: MP3, 24kHz, with SSML marks for word-level timing
- Config: `config/initializers/google_tts.rb`

**Resend:**
- Email delivery for PDF exports
- Config: `config/initializers/resend.rb`
- Mailer: `app/mailers/export_mailer.rb`

### Real-time Features

**ActionCable with solid_cable** (database-backed, no Redis):
- `ChatChannel` - Authenticated WebSocket for chat streaming
- Turbo Streams broadcast message chunks as they arrive
- Config: `config/cable.yml`

**Streaming Flow:**
1. User submits message via `MessagesController#create`
2. Creates placeholder assistant message
3. Enqueues `ChatResponseJob`
4. Job streams chunks via `Message#broadcast_append_chunk`
5. Stimulus controller auto-scrolls and renders markdown

### Services & Concerns

**Services (`app/services/`):**
- `CptChatService` - RAG orchestration, prompt building, knowledge retrieval
- `PdfExporters::Base` - Base PDF exporter
- `PdfExporters::AbcWorksheet` - ABC worksheet PDF
- `PdfExporters::AlternativeThought` - Alternative thought PDF
- `PdfExporters::StuckPoint` - Stuck point PDF
- `PdfExporters::Baseline` - Baseline assessment PDF

**Controller Concerns (`app/controllers/concerns/`):**
- `InlineFormRenderable` - Turbo Frame inline editing support
- `Exportable` - PDF export and email sharing actions
- `StuckPointChildResource` - Shared logic for nested resources (ABC, Alternative Thoughts)
- `IndexEventContentHelper` - Content path tracking for parent/child updates

**Model Concerns (`app/models/concerns/`):**
- `ExportConfig` - Centralized export configuration (titles, filenames, subjects)

### Key Routes

- Root: `dashboard#index` - main shell with sidebar navigation
- Index Events: full CRUD with nested resources
- Shallow routes for stuck_points, abc_worksheets, alternative_thoughts

### Frontend Stack

- Bootstrap 5.3 with custom SCSS in `app/assets/stylesheets/`
- Hotwire (Turbo + Stimulus) for interactivity
- importmap-rails for JavaScript modules
- Font Awesome for icons
- 22 Stimulus controllers for rich interactivity

**Key Stimulus Controllers:**
- `chat_controller` - ActionCable subscription, auto-scroll
- `audio_player_controller` - TTS playback with word highlighting
- `sidebar_toggle_controller` - Accordion navigation
- `column_resize_controller` - Drag-to-resize columns
- `unsaved_changes_controller` - Form change detection

### Storage

**Database:** PostgreSQL with pgvector extension
- Vector similarity search for RAG
- Config: `config/database.yml`

**File Storage (ActiveStorage):**
- Development: Local disk (`tmp/storage/`)
- Production: Database-backed (`active_storage_db` gem for Heroku)
- Audio files: Immutable with 1-year cache headers

## Key Patterns

**Bidirectional Sync:**
- `StuckPoint.statement` syncs to all `AbcWorksheet.beliefs`
- `AbcWorksheet.beliefs` can update back to `StuckPoint.statement`
- Implemented via `sync_beliefs_to_worksheets` with `except_id` to prevent loops

**Focus Context:**
- `ApplicationController` sets `@focus_context` hash with resource type/ID
- Passed to AI chat for contextually aware responses
- Example: If user views an ABC worksheet, Ross knows what they're working on

**Inline Editing (Turbo Frames):**
- Click title to fetch edit form in same frame
- Submit replaces form with display view via Turbo Stream
- Progressive enhancement: fallback redirects if no JS

## Testing

- **Framework:** Minitest with parallel execution
- **Data:** Fixture-based (YAML fixtures in `test/fixtures/`)
- **Database:** PostgreSQL (`cpt_with_ross_test`)

**Test Structure:**
```
test/
├── models/           # Unit tests
├── controllers/      # Controller tests
├── channels/         # ActionCable tests
├── system/           # E2E browser tests
├── integration/      # Integration tests
├── mailers/          # Mailer tests
└── fixtures/         # Test data (YAML)
```

## Code Style

- Ruby: Single quotes, 120 char line limit (see `.rubocop.yml`)
- Use `find_each` for iterating ActiveRecord collections in models/controllers
