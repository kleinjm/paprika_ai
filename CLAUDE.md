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
bin/rails test  # Run all tests
```

### Linting
```bash
bundle exec rubocop  # Ruby linting
```

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
The application uses Google Gemini API (gemini-2.0-flash model) as the primary AI service. The API key must be set in the `GEMINI_API_KEY` environment variable.

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