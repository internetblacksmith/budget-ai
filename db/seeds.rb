# Seeds file for Budget AI development/testing
# This creates mock transaction data for UI testing without touching real data

puts "Seeding mock transaction data..."

# Only run seeds in development mode, not in test mode
unless Rails.env.development?
  puts "Seeds only run in development mode. Your production/test data is safe."
  exit 0
end

# Clear existing data in development only
Transaction.destroy_all
ImportJob.destroy_all

# Mock Emma-imported transactions
emma_transactions = [
  {
    date: 2.weeks.ago,
    description: "TESCO STORES 2746",
    amount: -45.67,
    category: "Shopping",
    account: "Current Account",
    transaction_id: "emma_001",
    source: "emma_export",
    transaction_type: "DEB",
    balance: 1250.33
  },
  {
    date: 2.weeks.ago,
    description: "SALARY PAYMENT",
    amount: 2500.00,
    category: "Income",
    account: "Current Account",
    transaction_id: "emma_002",
    source: "emma_export",
    transaction_type: "CR",
    balance: 2795.00
  },
  {
    date: 1.week.ago,
    description: "AMAZON PRIME",
    amount: -8.99,
    category: "Subscriptions",
    account: "Current Account",
    transaction_id: "emma_003",
    source: "emma_export",
    transaction_type: "DEB",
    balance: 2786.01
  },
  {
    date: 5.days.ago,
    description: "ASDA STORES",
    amount: -78.45,
    category: "Shopping",
    account: "Current Account",
    transaction_id: "emma_004",
    source: "emma_export",
    transaction_type: "DEB",
    balance: 2707.56
  },
  {
    date: 3.days.ago,
    description: "FREELANCE PAYMENT",
    amount: 500.00,
    category: "Income",
    account: "Current Account",
    transaction_id: "emma_005",
    source: "emma_export",
    transaction_type: "CR",
    balance: 3207.56
  },
  {
    date: 2.days.ago,
    description: "COSTA COFFEE",
    amount: -4.50,
    category: "Food & Drink",
    account: "Current Account",
    transaction_id: "emma_006",
    source: "emma_export",
    transaction_type: "DEB",
    balance: 3203.06
  },
  {
    date: 1.day.ago,
    description: "RENT PAYMENT",
    amount: -850.00,
    category: "Housing",
    account: "Current Account",
    transaction_id: "emma_007",
    source: "emma_export",
    transaction_type: "DEB",
    balance: 2353.06
  },
  {
    date: 1.week.ago,
    description: "Spotify Premium",
    amount: -9.99,
    category: "Entertainment",
    account: "Savings Account",
    transaction_id: "emma_008",
    source: "emma_export"
  },
  {
    date: 4.days.ago,
    description: "Uber",
    amount: -12.50,
    category: "Transport",
    account: "Savings Account",
    transaction_id: "emma_009",
    source: "emma_export"
  },
  {
    date: 3.days.ago,
    description: "Sainsbury's",
    amount: -67.23,
    category: "Groceries",
    account: "Savings Account",
    transaction_id: "emma_010",
    source: "emma_export"
  },
  {
    date: 2.days.ago,
    description: "Cashback Reward",
    amount: 5.00,
    category: "Rewards",
    account: "Savings Account",
    transaction_id: "emma_011",
    source: "emma_export"
  }
]

# Create transactions
puts "Creating #{emma_transactions.length} Emma-imported transactions..."
emma_transactions.each do |attrs|
  Transaction.create!(attrs)
end

# Create a sample import job
puts "Creating sample import job..."
ImportJob.create!(
  filename: "emma_export.csv",
  status: "completed",
  total_files: 1,
  processed_files: 1,
  imported_count: emma_transactions.length,
  started_at: 1.hour.ago,
  completed_at: 45.minutes.ago,
  source: "emma_export"
)

# Summary
total_transactions = Transaction.count
total_income = Transaction.income.sum(:amount)
total_expenses = Transaction.expenses.sum(:amount).abs
net_balance = total_income - total_expenses

puts "\nSeeding completed!"
puts "Created #{total_transactions} mock transactions"
puts "Total Income: #{total_income.round(2)}"
puts "Total Expenses: #{total_expenses.round(2)}"
puts "Net Balance: #{net_balance.round(2)}"
puts "\nThis is MOCK DATA for development/testing only"
