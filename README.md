<p align="center">
  <img src="public/logo.png" alt="CPT with Ross Logo" width="120" height="120">
</p>

<h1 align="center">CPT with Ross</h1>

<p align="center">
  <strong>AI-Powered Cognitive Processing Therapy Companion</strong>
</p>

<p align="center">
  A production-ready Rails application combining evidence-based PTSD therapy with modern AI capabilities, featuring real-time streaming responses, RAG-enhanced conversations, and voice synthesis.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.3.5-CC342D?style=flat-square&logo=ruby&logoColor=white" alt="Ruby">
  <img src="https://img.shields.io/badge/Rails-7.1-CC0000?style=flat-square&logo=rubyonrails&logoColor=white" alt="Rails">
  <img src="https://img.shields.io/badge/PostgreSQL-pgvector-4169E1?style=flat-square&logo=postgresql&logoColor=white" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-1a1a1a?style=flat-square" alt="Hotwire">
  <img src="https://img.shields.io/badge/AI-Gemini%202.5-4285F4?style=flat-square&logo=google-cloud&logoColor=white" alt="Gemini 2.5">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
</p>

---

## Educational Purpose Notice

This project was developed for **educational and research purposes** as a demonstration of integrating modern AI technologies with healthcare applications. The knowledge base used for RAG (Retrieval-Augmented Generation) contains materials utilized under the **fair use doctrine** for educational purposes (17 U.S.C. Section 107), which permits limited use of copyrighted material for purposes such as teaching, scholarship, and research.

**This application is not intended for commercial use** and is provided as a portfolio demonstration of full-stack Rails development, LLM integration, and AI-assisted healthcare tooling.

---

## The Problem

Post-Traumatic Stress Disorder (PTSD) affects millions of people worldwide. Cognitive Processing Therapy (CPT) is one of the most effective evidence-based treatments, but access to trained therapists is limited and expensive. Many individuals working through CPT between sessions need guidance on worksheets and exercises but have nowhere to turn.

## The Solution

**CPT with Ross** bridges this gap by providing an AI companion that understands CPT methodology. Users can:
- Work through structured CPT worksheets with contextual AI guidance
- Have their progress informed by RAG-retrieved therapy knowledge
- Listen to responses via natural voice synthesis
- Export and share progress with their therapist

---

## Technical Highlights

### Real-Time Streaming Architecture
```
User Input → Turbo Stream → ChatResponseJob → RubyLLM → Gemini 2.5 Flash
                                    ↓
                        Token-by-token streaming
                                    ↓
                        Turbo Broadcast → Live DOM Update
```
- **Zero-latency perceived response** via Turbo Streams
- Background job processing with Solid Queue
- ActionCable broadcasting for real-time updates

### RAG (Retrieval-Augmented Generation) Pipeline
```
User Query → Embedding Generation → pgvector Similarity Search
                                              ↓
                                    Top-K Knowledge Chunks
                                              ↓
                                    Context-Injected Prompt → LLM
```
- **768-dimensional embeddings** stored in PostgreSQL with pgvector
- HNSW indexing for sub-millisecond vector similarity search
- Domain-specific CPT knowledge retrieval

### Voice Synthesis Integration
- Google Cloud Text-to-Speech (Neural2 voices)
- SSML markup with timepoint synchronization
- Audio streaming via ActiveStorage

### Redis-Free Architecture
- **Solid Queue** for background jobs (PostgreSQL-backed)
- **Solid Cable** for WebSocket connections (PostgreSQL-backed)
- Simplified deployment with no external dependencies

---

## Features

| Feature | Description |
|---------|-------------|
| **Index Event Tracking** | Document and process traumatic experiences with structured metadata |
| **PCL-5 Assessment** | Complete PTSD Checklist with automatic scoring and progress tracking |
| **Stuck Point Analysis** | Identify cognitive stuck points with AI-assisted pattern recognition |
| **ABC Worksheets** | Interactive A-B-C cognitive worksheets with emotion intensity tracking |
| **Alternative Thoughts** | Guided cognitive restructuring with 7 exploring questions and 5 thinking patterns |
| **AI Chat Companion** | Context-aware conversations powered by Gemini 2.5 Flash with streaming responses |
| **Voice Responses** | Natural text-to-speech with synchronized highlighting |
| **PDF Export** | Professional PDF generation for all worksheets |
| **Email Sharing** | Send progress reports directly to therapists |

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Client Browser                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Turbo     │  │  Stimulus   │  │   Audio     │  │   ActionCable       │ │
│  │   Frames    │  │ Controllers │  │   Player    │  │   WebSocket         │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
└─────────┼────────────────┼────────────────┼────────────────────┼────────────┘
          │                │                │                    │
          ▼                ▼                ▼                    ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                              Rails 7.1 Application                            │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                         Controllers                                     │  │
│  │   Dashboard │ IndexEvents │ StuckPoints │ Worksheets │ Chat │ Messages  │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                          Services                                       │  │
│  │   CptChatService (RAG + LLM orchestration)                              │  │
│  │   PDF Exporters (Prawn-based document generation)                       │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                        Background Jobs                                  │  │
│  │   ChatResponseJob │ TextToSpeechJob │ KnowledgeImportJob                │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────┘
          │                                                      │
          ▼                                                      ▼
┌─────────────────────┐                          ┌─────────────────────────────┐
│    PostgreSQL       │                          │      External Services      │
│  ┌───────────────┐  │                          │  ┌───────────────────────┐  │
│  │   App Data    │  │                          │  │   Google Vertex AI    │  │
│  ├───────────────┤  │                          │  │   (Gemini 2.5 Flash)  │  │
│  │   pgvector    │  │                          │  ├───────────────────────┤  │
│  │  (embeddings) │  │                          │  │   Google Cloud TTS    │  │
│  ├───────────────┤  │                          │  │   (Neural2 voices)    │  │
│  │  Solid Queue  │  │                          │  ├───────────────────────┤  │
│  │  Solid Cable  │  │                          │  │   Resend              │  │
│  │  ActiveStorage│  │                          │  │   (transactional)     │  │
│  └───────────────┘  │                          │  └───────────────────────┘  │
└─────────────────────┘                          └─────────────────────────────┘
```

### Domain Model

```
User (Devise authentication)
  │
  ├── Chat (persistent AI conversation)
  │     └── Message[] (with token tracking, TTS timepoints)
  │           └── ToolCall[] (AI function calls)
  │
  └── IndexEvent[] (traumatic events)
        │
        ├── Baseline (1:1, auto-created)
        │     ├── PCL-5 Assessment (20 questions, 0-80 scoring)
        │     └── Impact Statement (narrative processing)
        │
        └── StuckPoint[] (cognitive stuck points)
              │
              ├── AbcWorksheet[] (A-B-C analysis)
              │     ├── Activating Event
              │     ├── Beliefs (synced with StuckPoint)
              │     └── Consequences + Emotions (12 discrete emotions, 0-10 intensity)
              │
              └── AlternativeThought[] (cognitive restructuring)
                    ├── 7 Exploring Questions
                    ├── 5 Thinking Patterns
                    ├── Alternative Thought + Belief Ratings
                    └── Before/After Emotion Comparison
```

---

## Tech Stack

### Core Framework
| Technology | Purpose |
|------------|---------|
| Ruby 3.3.5 | Modern Ruby with YJIT performance |
| Rails 7.1 | Full-stack web framework |
| PostgreSQL | Primary database with pgvector |
| Hotwire | Turbo + Stimulus for reactive UI |

### AI & Machine Learning
| Technology | Purpose |
|------------|---------|
| RubyLLM | LLM abstraction layer |
| Google Vertex AI | Gemini 2.5 Flash for chat |
| pgvector | Vector similarity search |
| neighbor gem | Rails integration for pgvector |

### Background Processing
| Technology | Purpose |
|------------|---------|
| Solid Queue | PostgreSQL-backed job queue |
| Solid Cable | PostgreSQL-backed ActionCable |
| ActiveJob | Job orchestration |

### External Services
| Service | Purpose |
|---------|---------|
| Google Cloud TTS | Neural2 voice synthesis |
| Resend | Transactional email delivery |
| ActiveStorage DB | PostgreSQL blob storage |

---

## Getting Started

### Prerequisites

- Ruby 3.3.5 (via rbenv, asdf, or similar)
- PostgreSQL 14+ with pgvector extension
- Node.js 20+
- Google Cloud account with Vertex AI enabled

### Installation

```bash
# Clone the repository
git clone https://github.com/ButlerJAL/cpt-with-ross.git
cd cpt-with-ross

# Install dependencies and setup database
bin/setup

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Authenticate with Google Cloud
gcloud auth application-default login

# Start the server
bin/rails server
```

### Environment Variables

```bash
# Google Cloud (Vertex AI + TTS)
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1

# Email (Resend)
RESEND_API_KEY=re_xxx

# Rails
RAILS_MASTER_KEY=xxx
SECRET_KEY_BASE=xxx
```

---

## Development

### Commands

```bash
# Development
bin/rails server              # Start web server
bin/rails console             # Interactive console
bin/rails solid_queue:start   # Start background worker

# Database
bin/rails db:migrate          # Run migrations
bin/rails db:seed             # Seed demo data

# Knowledge Base
bin/rails knowledge:import       # Import embeddings (async)
bin/rails knowledge:import_sync  # Import embeddings (sync)
bin/rails knowledge:clear        # Clear all embeddings

# Testing
bin/rails test                # Run test suite

# Linting
npm run lint:check            # Check Ruby + JS
npm run lint:fix              # Auto-fix issues
```

### Code Quality

- **RuboCop** - Ruby style enforcement (120 char lines, single quotes)
- **ERB Lint** - Template linting
- **ESLint** - JavaScript linting
- **GitHub Actions** - Automated CI on all PRs

---

## Deployment

### Docker

```bash
docker build -t cpt-with-ross .
docker run -p 3000:3000 \
  -e DATABASE_URL=postgres://... \
  -e GOOGLE_CLOUD_PROJECT=... \
  cpt-with-ross
```

### Heroku

Optimized for Heroku deployment:
- No Redis required (Solid Queue/Cable use PostgreSQL)
- No S3 required (ActiveStorage uses PostgreSQL)
- Procfile included for web + worker dynos

```bash
heroku create
heroku addons:create heroku-postgresql:essential-0
heroku config:set GOOGLE_CLOUD_PROJECT=xxx
git push heroku main
heroku run rails db:migrate
```

---

## Project Structure

```
app/
├── controllers/          # Request handling
│   ├── concerns/         # Shared controller logic (Exportable, etc.)
│   └── users/            # Devise customizations
├── models/               # Domain models with business logic
│   └── concerns/         # Shared model concerns
├── services/             # Business logic orchestration
│   ├── cpt_chat_service.rb    # RAG + LLM pipeline
│   └── pdf_exporters/         # Document generation
├── jobs/                 # Background processing
├── mailers/              # Email delivery
├── javascript/
│   └── controllers/      # Stimulus controllers (21 controllers)
└── views/
    ├── layouts/          # Application shell
    ├── shared/           # Reusable partials
    └── [resources]/      # Resource-specific views
```

---

## CI/CD Pipeline

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `code-quality.yml` | Push/PR | RuboCop, ERB Lint, ESLint |
| `deploy.yml` | Push to main | Automated deployment |
| `pr-compliance.yml` | PR | Standards enforcement |
| `stale.yml` | Schedule | Issue hygiene |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Ensure linting passes (`npm run lint:check`)
4. Ensure tests pass (`bin/rails test`)
5. Commit with clear messages
6. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Disclaimer

**CPT with Ross is a self-help tool and is not a substitute for professional mental health treatment.** This application is designed to supplement, not replace, work with a licensed mental health professional. If you are experiencing a mental health crisis, please contact a mental health professional or crisis helpline immediately.

**Educational Use:** This project is intended for educational and portfolio demonstration purposes. The RAG knowledge base utilizes materials under fair use provisions for educational purposes. This application is not intended for commercial deployment without proper licensing of source materials.

---

<p align="center">
  <sub>Built with care for those healing from trauma</sub>
</p>
