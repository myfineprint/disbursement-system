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
    current_time = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    File.open(temp_file, 'w') do |f|
      File.foreach('merchants.csv') do |line|
        # Skip header
        next if line.start_with?('id;')

        # Append timestamp columns
        f.write(line.strip + ";#{current_time};#{current_time}\n")
      end
    end

    # Build psql command - include all columns from CSV
    psql_cmd = "psql -h #{host} -p #{port} -U #{username} -d #{database}"
    psql_cmd +=
      " -c \"\\COPY merchants (id, reference, email, live_on, disbursement_frequency, minimum_monthly_fee, created_at, updated_at) FROM '#{File.expand_path(temp_file)}' WITH (FORMAT csv, DELIMITER ';', HEADER false);\""

    # Set password if provided
    ENV['PGPASSWORD'] = password if password

    puts "Running: #{psql_cmd}"
    result = system(psql_cmd)

    # Clean up
    FileUtils.rm_f(temp_file)
    ENV.delete('PGPASSWORD') if password

    if result
      count = Merchant.count
      puts "✅ Imported #{count} merchants using merchants.csv"
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
    current_time = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    File.open(temp_file, 'w') do |f|
      File.foreach('orders.csv') do |line|
        # Skip header
        next if line.start_with?('id;')

        # Append updated_at column if not already present
        if line.count(';') == 3 # id, merchant_reference, amount, created_at
          f.write(line.strip + ";#{current_time}\n")
        else
          f.write(line)
        end
      end
    end

    # Build psql command - include all columns from CSV
    psql_cmd = "psql -h #{host} -p #{port} -U #{username} -d #{database}"
    psql_cmd +=
      " -c \"\\COPY orders (id, merchant_reference, amount, created_at, updated_at) FROM '#{File.expand_path(temp_file)}' WITH (FORMAT csv, DELIMITER ';', HEADER false);\""

    # Set password if provided
    ENV['PGPASSWORD'] = password if password

    puts "Running: #{psql_cmd}"
    result = system(psql_cmd)

    # Clean up
    FileUtils.rm_f(temp_file)
    ENV.delete('PGPASSWORD') if password

    if result
      count = Order.count
      puts "✅ Imported #{count} orders using orders.csv"
    else
      puts '❌ Failed to import orders'
      exit 1
    end
  end

  desc 'Import all data'
  task all: :environment do
    puts '=== Importing All Data==='

    # Import merchants first
    Rake::Task['import:merchants'].invoke

    # Import orders
    Rake::Task['import:orders'].invoke

    puts "\n=== Import Summary ==="
    puts "Merchants: #{Merchant.count}"
    puts "Orders: #{Order.count}"
    puts "Disbursements: #{Disbursement.count}"
    puts "Commissions: #{Commission.count}"
  end
end
