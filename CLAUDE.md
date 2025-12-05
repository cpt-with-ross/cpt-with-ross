# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CPT with Ross is an AI-assisted self-help web application for Cognitive Processing Therapy (CPT) for PTSD. Built with Rails 7.1, PostgreSQL (with pgvector), and Hotwire (Turbo/Stimulus).

## Common Commands

```bash
# Setup
bin/setup                          # Full dev environment setup (installs deps, prepares DB)
bin/rails db:prepare               # Create/migrate database

# Development
bin/rails server                   # Start Rails server
bin/rails console                  # Rails console

# Database
bin/rails db:migrate               # Run migrations
bin/rails db:seed                  # Seed database

# Testing
bin/rails test                     # Run all tests
bin/rails test test/models/user_test.rb           # Run single test file
bin/rails test test/models/user_test.rb:10        # Run specific test at line

# Linting
npm run lint:check                 # Check all linting (Ruby + JS)
npm run lint:fix                   # Auto-fix all linting issues
bundle exec rubocop                # Ruby linting only
bundle exec rubocop -A             # Ruby auto-fix
bundle exec erb_lint --lint-all    # ERB template linting
npx eslint .                       # JavaScript linting
```

## Architecture

### Domain Model Hierarchy

The core CPT therapy workflow follows a hierarchical structure:

```
User (Devise auth)
  └── IndexEvent (traumatic event being processed)
        ├── ImpactStatement (1:1, auto-created with IndexEvent)
        └── StuckPoint[] (negative thoughts/beliefs)
              ├── AbcWorksheet[] (A-B-C cognitive worksheets)
              └── AlternativeThought[] (balanced thought challenges)
```

### AI Chat System

Uses `ruby_llm` gem with a chat/message/tool_call pattern:
- `Chat` - conversation container (uses `acts_as_chat`)
- `Message` - individual messages with role, content, token tracking
- `ToolCall` - function calls made by the AI
- `Model` - LLM model configurations

### Key Routes

- Root: `dashboard#index` - main shell with sidebar navigation
- Index Events: full CRUD with nested resources
- Shallow routes for stuck_points, abc_worksheets, alternative_thoughts

### Frontend Stack

- Bootstrap 5.3 with custom SCSS in `app/assets/stylesheets/`
- Hotwire (Turbo + Stimulus) for interactivity
- importmap-rails for JavaScript modules
- Font Awesome for icons

## Code Style

- Ruby: Single quotes, 120 char line limit (see `.rubocop.yml`)
- Use `find_each` for iterating ActiveRecord collections in models/controllers
