require 'fileutils'

namespace :import do
  desc 'Import merchants'
  task merchants: :environment do
    puts '=== Importing Merchants ==='

    # Get database configuration
    db_config = Rails.application.config.database_configuration[Rails.env]
    host = db_config['host'] || 'localhost'
    port = db_config['port'] || 5432
    database = db_config['database']
    username = db_config['username'] || ENV['USER'] || 'postgres'
    password = db_config['password']

    # Create temporary file with proper format
    temp_file = 'merchants_temp.csv'
    File.open(temp_file, 'w') do |f|
      File.foreach('merchants.csv') do |line|
        # Skip header
        next if line.start_with?('id;')

        f.write(line)
      end
    end

    # Build psql command - include all columns from CSV
    psql_cmd = "psql -h #{host} -p #{port} -U #{username} -d #{database}"
    psql_cmd +=
      " -c \"\\COPY merchants (id, reference, email, live_on, disbursement_frequency, minimum_monthly_fee) FROM '#{File.expand_path(temp_file)}' WITH (FORMAT csv, DELIMITER ';', HEADER false);\""

    # Set password if provided
    ENV['PGPASSWORD'] = password if password

    puts "Running: #{psql_cmd}"
    result = system(psql_cmd)

    # Clean up
    FileUtils.rm_f(temp_file)
    ENV.delete('PGPASSWORD') if password

    if result
      count = Merchant.count
      puts "✅ Imported #{count} merchants using PostgreSQL COPY"
    else
      puts '❌ Failed to import merchants'
      exit 1
    end
  end

  desc 'Import orders'
  task orders: :environment do
    puts '=== Importing Orders ==='

    # Get database configuration
    db_config = Rails.application.config.database_configuration[Rails.env]
    host = db_config['host'] || 'localhost'
    port = db_config['port'] || 5432
    database = db_config['database']
    username = db_config['username'] || ENV['USER'] || 'postgres'
    password = db_config['password']

    # Create temporary file with proper format
    temp_file = 'orders_temp.csv'
    File.open(temp_file, 'w') do |f|
      File.foreach('orders.csv') do |line|
        # Skip header
        next if line.start_with?('id;')

        f.write(line)
      end
    end

    # Build psql command - include all columns from CSV
    psql_cmd = "psql -h #{host} -p #{port} -U #{username} -d #{database}"
    psql_cmd +=
      " -c \"\\COPY orders (id, merchant_reference, amount, created_at) FROM '#{File.expand_path(temp_file)}' WITH (FORMAT csv, DELIMITER ';', HEADER false);\""

    # Set password if provided
    ENV['PGPASSWORD'] = password if password

    puts "Running: #{psql_cmd}"
    result = system(psql_cmd)

    # Clean up
    FileUtils.rm_f(temp_file)
    ENV.delete('PGPASSWORD') if password

    if result
      count = Order.count
      puts "✅ Imported #{count} orders using PostgreSQL COPY"
    else
      puts '❌ Failed to import orders'
      exit 1
    end
  end

  desc 'Import all data using PostgreSQL COPY (fastest)'
  task all: :environment do
    puts '=== Importing All Data (PostgreSQL COPY) ==='

    # Import merchants first
    Rake::Task['import:merchants'].invoke

    # Import orders
    Rake::Task['import:orders'].invoke

    puts "\n=== Import Summary ==="
    puts "Merchants: #{Merchant.count}"
    puts "Orders: #{Order.count}"
    puts "Disbursements: #{Disbursement.count}"
    puts "Disbursement Orders: #{DisbursementOrder.count}"
  end
end
