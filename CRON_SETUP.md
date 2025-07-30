# Cron Job Setup for Disbursements Rails App

This project uses **Sidekiq with sidekiq-cron** for scheduling recurring tasks.

## Why Sidekiq?

**Advantages:**
- Robust job queuing with Redis
- Better monitoring and error handling
- Scalable for high-volume processing
- Job retry mechanisms
- Web UI for monitoring
- Integration with Rails' Active Job system

## Setup

### 1. Install Dependencies
```bash
bundle install
```

### 2. Install and Start Redis
```bash
# macOS
brew install redis
brew services start redis

# Linux
sudo apt-get install redis-server
sudo systemctl start redis
```

### 3. Start Sidekiq
```bash
bundle exec sidekiq
```

### 4. Start Rails Server
```bash
rails server
```

## Configuration

### Job Classes
Create job classes in `app/jobs/` directory:

```ruby
# app/jobs/disbursement_processing_job.rb
class DisbursementProcessingJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Processing disbursements at #{Time.current}"
    
    # Add your disbursement processing logic here
    # - Process pending disbursements
    # - Send notifications
    # - Update statuses
    # - Generate reports
  end
end
```

### Scheduled Jobs
Edit `config/sidekiq_cron.yml` to define your scheduled jobs:

```yaml
disbursement_processing:
  cron: "0 * * * *"  # Every hour
  class: "DisbursementProcessingJob"
  queue: default

daily_report_generation:
  cron: "0 6 * * *"  # Daily at 6 AM
  class: "ReportGenerationJob"
  queue: reports
```

## Monitoring

### Sidekiq Web UI
Add to `config/routes.rb`:
```ruby
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'
```

Then visit `http://localhost:3000/sidekiq` to monitor jobs.

### Logs
- Check Sidekiq logs in the terminal where it's running
- Check Rails logs in `log/development.log`

## Development Workflow

1. **Start Redis**: `brew services start redis`
2. **Start Sidekiq**: `bundle exec sidekiq`
3. **Start Rails**: `rails server`
4. **Monitor**: Visit `/sidekiq` in your browser

## Production Deployment

Make sure to:
- Set `REDIS_URL` environment variable
- Configure Sidekiq as a service (using systemd, upstart, etc.)
- Set up proper logging and monitoring
- Configure job retry policies in your job classes 