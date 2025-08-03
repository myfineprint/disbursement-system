#  bundle exec rake "monthly_minimum_defaults:process_yearly[2022,2023]"
namespace :monthly_minimum_defaults do
  desc 'Process monthly minimum defaults for a year or range of years'
  task :process_yearly, %i[start_year end_year] => :environment do |_task, args|
    start_year = args[:start_year]&.to_i || Date.current.year
    end_year = args[:end_year]&.to_i || start_year

    start_year_date = Date.new(start_year, 1, 1)
    end_year_date = Date.new(end_year, 12, 31) + 1.day

    puts '=== Processing Monthly Minimum Defaults for Date Range ==='
    puts "Start Date: #{start_year_date.strftime('%B %Y')}"
    puts "End Date: #{end_year_date.strftime('%B %Y')}"
    puts '=' * 60

    # Process each month in the range
    current_date = start_year_date
    while current_date <= end_year_date
      puts "\n#{'=' * 60}"
      puts "PROCESSING: #{current_date.strftime('%B %Y')}"
      puts '=' * 60

      process_month(current_date)
      current_date = current_date.next_month
    end
  end

  # bundle exec rake "monthly_minimum_defaults:process_month[2023,12]"
  desc 'Process monthly minimum defaults for a specific month '
  task :process_month, %i[year month] => :environment do |_task, args|
    year = args[:year]&.to_i || Date.current.year
    month = args[:month]&.to_i || Date.current.month

    calculation_date = Date.new(year, month, 1)
    process_month(calculation_date)
  end

  private

  def process_month(calculation_date)
    puts "  Processing monthly minimum defaults for #{calculation_date.strftime('%B %Y')}"

    # Use the job to process the month (job will calculate previous month internally)
    CalculateMonthlyMinimumDefaultsJob.perform_later(date: calculation_date)

    puts "    ✅ Queued job for #{calculation_date.strftime('%B %Y')}"
  end
end
