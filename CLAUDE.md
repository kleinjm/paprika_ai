# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.0 application that integrates with the Paprika Recipe Manager database to provide AI-powered features for meal planning, recipe analysis, and ingredient substitutions.

## Common Development Commands

### Dependencies
```bash
bundle install  # Install Ruby gems
yarn install    # Install Node packages
```

### Development Server
```bash
bin/rails server  # Start Rails server on localhost:3000
bin/dev          # Start Rails server with CSS watching (requires foreman)
```

### CSS Building
```bash
yarn build:css     # Build CSS once
yarn watch:css     # Watch and rebuild CSS on changes
```

### Database
```bash
bin/rails db:create   # Create PostgreSQL development database
bin/rails db:migrate  # Run migrations
bin/rails db:seed     # Seed database
```

### Console
```bash
bin/rails console  # Start Rails console
```

### Testing
```bash
bundle exec rspec  # Run the test suite (RSpec; CI enforces 100% line coverage)
```

### Linting
```bash
bundle exec rubocop  # Ruby linting
```

## Deploying (CI + Render)

Deploys are gated on CI: a push to `main` runs RSpec via GitHub Actions
(`.github/workflows/ci.yml`), and only a green run triggers the Render deploy
hook. A red run deploys nothing.

**Any push to `main` MUST be followed by polling CI until it passes.** After
pushing:

1. Poll the CI run for the pushed commit until it completes, e.g.:
   ```bash
   RUN=$(gh run list --branch main --limit 1 --json databaseId --jq '.[0].databaseId')
   gh run watch "$RUN" --exit-status
   ```
2. **If red**, read the failures (`gh run view "$RUN" --log-failed`), fix them
   locally, run `bundle exec rspec` to confirm green + 100% coverage, then push
   again and poll again — repeat until green. Note RSpec can exit non-zero on a
   coverage shortfall even with 0 test failures, so check coverage, not just the
   example count.
3. Do not consider the work done until CI is green. When it is, the Render
   deploy is triggered automatically; optionally confirm it went live with the
   Render CLI (`render deploys list <service-id>`) or `curl -sI https://paprika-ai.onrender.com/up`.

## Architecture

### Database Configuration
- **Primary database**: PostgreSQL for development/production (`paprika_ai_development`)
- **Read-only database**: SQLite connection to Paprika Recipe Manager database at `/Users/jklein/Library/Group Containers/72KVKW69K8.com.hindsightlabs.paprika.mac.v3/Data/Database/Paprika.sqlite`

### Core Components

**Models** (`app/models/paprika/`):
- All Paprika models inherit from `Paprika::ApplicationRecord` which connects to the read-only SQLite database
- Key models: Recipe, Category, Menu, MenuItem, Meal, GroceryList, GroceryItem
- Recipe has many categories through a join table structure

**Services** (`app/services/`):
- `GeminiService`: Handles Google Gemini AI API integration (primary AI service)
- `ChatGptService`: Handles OpenAI ChatGPT integration (optional)

**Controllers**:
- `HomeController`: Main controller handling recipe analysis, substitutions, and meal planning

**Forms**:
- `MealPlanForm`: Form object for building meal plan prompts with categories and constraints

### AI Integration
The application uses the Google Gemini API as the primary AI service, via `GeminiService`, which tries a fallback chain of models on transient errors. The API key is read from Rails development credentials at `google.gemini.api_key` (`bin/rails credentials:edit --environment development`).

### CSS/JS Architecture
- Uses Bootstrap 5.3 with SASS compilation
- CSS is built using a Node.js pipeline (sass → postcss → autoprefixer)
- JavaScript uses Rails' importmap for ESM modules
- Hotwire (Turbo + Stimulus) for dynamic interactions

### Key Routes
- `/` - Home page with recipe list and AI features
- `/home/analyze_recipe` - Analyze a recipe with AI
- `/home/suggest_substitutions` - Get ingredient substitution suggestions
- `/home/suggest_meal_plan` - Generate meal plans based on selected categories