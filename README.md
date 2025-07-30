# Disbursements - Cron Job Application

A streamlined Rails application focused on processing disbursements via scheduled background jobs.

## Features

- **Sidekiq** for background job processing
- **sidekiq-cron** for scheduled job execution
- **PostgreSQL** for data storage
- **Redis** for job queuing
- **RuboCop** for code quality

## Setup

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Setup database:**
   ```bash
   rails db:create
   rails db:migrate
   ```

3. **Start Redis:**
   ```bash
   brew services start redis  # macOS
   ```

4. **Start Sidekiq:**
   ```bash
   bundle exec sidekiq
   ```

## Cron Jobs

Scheduled jobs are defined in `config/sidekiq_cron.yml`:

```yaml
disbursement_processing:
  cron: "0 * * * *"  # Every hour
  class: "DisbursementProcessingJob"
  queue: default
```

## Job Classes

Create job classes in `app/jobs/`:

```ruby
class DisbursementProcessingJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Your disbursement processing logic here
    Rails.logger.info "Processing disbursements at #{Time.current}"
  end
end
```

## Development

- **Check code style:** `bundle exec rubocop`
- **Auto-fix issues:** `bundle exec rubocop -a`
- **Run jobs manually:** `rails console` then `DisbursementProcessingJob.perform_later`

## Project Structure

```
app/
├── jobs/           # Background job classes
└── models/         # ActiveRecord models

config/
├── sidekiq_cron.yml    # Scheduled job definitions
└── initializers/
    └── sidekiq.rb      # Sidekiq configuration
```

This is a minimal Rails application focused on background job processing without web interface components.
