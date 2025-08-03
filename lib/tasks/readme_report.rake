# lib/tasks/report.rake

# bundle exec rake "report:disbursement_summary"
namespace :report do
  desc 'Generate yearly financial disbursement report'
  task disbursement_summary: :environment do
    years =
      Disbursement.pluck(Arel.sql('DISTINCT EXTRACT(YEAR FROM disbursement_date)')).map(&:to_i).sort

    puts '| Year | # Disbursements | Amount Disbursed | Amount of Order Fees | # Monthly Fees Charged | Amount of Monthly Fees |'
    puts '|------|------------------|------------------|------------------------|------------------------|--------------------------|'

    years.each do |year|
      disbursements =
        Disbursement.where(disbursement_date: Date.new(year)..Date.new(year).end_of_year)
      monthly_fees =
        MonthlyMinimumFeeDefault.where(period_date: Date.new(year)..Date.new(year).end_of_year)

      num_disbursements = disbursements.count
      amount_disbursed = disbursements.sum(:total_net_amount)
      order_fees = disbursements.sum(:total_commission)
      monthly_fee_count = monthly_fees.count
      monthly_fee_sum = monthly_fees.sum(:defaulted_amount)

      puts "| #{year} | #{num_disbursements} | #{format('%.2f €', amount_disbursed)} | #{format('%.2f €', order_fees)} | #{monthly_fee_count} | #{format('%.2f €', monthly_fee_sum)} |"
    end
  end
end
