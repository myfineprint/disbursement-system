# bundle exec rake "disbursements:process_yearly[2023]"
# bundle exec rake "disbursements:process_yearly[2022,2024]"
namespace :disbursements do
  desc 'Process disbursements for a year or range of years'
  task :process_yearly, %i[start_year end_year] => :environment do |_task, args|
    start_year = args[:start_year]&.to_i || Date.current.year
    end_year = args[:end_year]&.to_i || start_year

    puts '=== Processing Disbursements for Year Range ==='
    puts "Start Year: #{start_year}"
    puts "End Year: #{end_year}"
    puts "Total Years: #{end_year - start_year + 1}"
    puts '=' * 60

    # Process each year
    (start_year..end_year).each do |year|
      puts "\n#{'=' * 60}"
      puts "PROCESSING YEAR: #{year}"
      puts '=' * 60

      # Process each day of the year
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year, 12, 31) + 1.day

      (start_date..end_date).each { |current_date| process_date(current_date) }
    end
  end

  private

  def process_date(date)
    puts "  Processing #{date.strftime('%Y-%m-%d')} (#{date.strftime('%A')})"

    DisbursementProcessingJob.perform_later(date)
  end
end
