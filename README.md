# Disbursements System

A streamlined Rails application focused on processing disbursements via scheduled background jobs.

#### 🛠 Setup Instructions

Clone the repository and install dependencies:

```bash
git clone https://github.com/myfineprint/disbursement-system.git
```

## Setup

1. **Install dependencies:**

   ```bash
   bundle install
   ```

2. **Setup database:**

   ```bash
   rails db:create db:migrate
   ```

3. **Start Redis:**

   ```bash
   brew services start redis  # macOS

   redis-server # Linux
   ```

4. **Start Servers:**

   ```bash
   bin/rails server        # Starts the Rails server

   bundle exec sidekiq     # Starts the Sidekiq worker
   ```

5. **Run Specs:**

   ```bash
   bundle exec rspec spec
   ```

## Usage guide

The CSV files (orders.csv, merchants.csv) are already included in the repo.

**Step 1: Import All Data**

```bash
bundle exec rake "import:all"
```

This imports all merchants and orders from their respective CSV files.

Incase you would ike to clear all databases, you can run:

```bash
bundle exec rake "cleanup:all"
```

**Step 2: Process Disbursements**

```bash
bundle exec rake "disbursements:process_yearly[2022,2023]"
```

You can replace 2022 and 2023 with any year you wish to process. This generates disbursements for each merchant based on their frequency (weekly or monthly).

**Step 3: Process Minimum Monthly Fee Defaults**

```bash
 bundle exec rake "monthly_minimum_defaults:process_yearly[2022,2023]"
```

This identifies merchants who didn’t generate enough in commissions to meet their minimum_monthly_fee. These merchants will be saved in a separate monthly_minimum_fee_defaults table. No fee is deducted — this step is only for tracking.

**Step 4: Generate Summary Report**

```bash
 bundle exec rake "report:disbursement_summary"
```

This prints a summary grouped by year:

- Number of disbursements

- Total amount disbursed to merchants

- Total order commissions

- Number of monthly fees charged

- Amount of monthly fees charged

For the data given in the task, this was the summary I was able to generate

| Year | Number of disbursements | Amount disbursed to merchants | Amount of order fees | Number of monthly fees charged | Amount of monthly fees charged |
| ---- | ----------------------- | ----------------------------- | -------------------- | ------------------------------ | ------------------------------ |
| 2022 | 1509                    | 36929324.90 €                 | 333672.58 €          | 26                             | 489.30 €                       |
| 2023 | 10391                   | 188564626.76 €                | 1709234.08 €         | 100                            | 1679.19 €                      |
