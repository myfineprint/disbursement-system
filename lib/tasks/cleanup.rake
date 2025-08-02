namespace :cleanup do
  desc 'Delete all data from all tables (merchants, orders, disbursements)'
  task all: :environment do
    puts '=== Cleaning up ALL data ==='

    # Get counts before deletion
    merchant_count = Merchant.count
    order_count = Order.count
    disbursement_count = Disbursement.count
    commission_count = Commission.count

    puts "Found #{merchant_count} merchants"
    puts "Found #{order_count} orders"
    puts "Found #{disbursement_count} disbursements"
    puts "Found #{commission_count} commissions"

    if merchant_count.zero? && order_count.zero? && disbursement_count.zero? &&
         commission_count.zero?
      puts 'No data to delete!'
      return
    end

    # Ask for confirmation
    print 'Are you sure you want to delete ALL data? This will delete everything! (y/n): '
    confirmation = $stdin.gets.chomp.downcase

    unless confirmation == 'y'
      puts 'Operation cancelled.'
      return
    end

    puts 'Deleting all data...'

    # Delete in the correct order (due to foreign key constraints)
    Commission.delete_all
    Disbursement.delete_all
    Order.delete_all
    Merchant.delete_all

    puts '✅ Successfully deleted all data!'
    puts "Deleted #{merchant_count} merchants"
    puts "Deleted #{order_count} orders"
    puts "Deleted #{disbursement_count} disbursements"
    puts "Deleted #{commission_count} commissions"
  end
end
