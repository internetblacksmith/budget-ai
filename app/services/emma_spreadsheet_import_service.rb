class EmmaSpreadsheetImportService
  attr_reader :errors, :imported_count

  def initialize(spreadsheet_id, oauth_tokens = nil, sheet_name = nil, on_progress: nil)
    @spreadsheet_id = spreadsheet_id
    @oauth_tokens = oauth_tokens
    @sheet_name = sheet_name
    @on_progress = on_progress
    @errors = []
    @imported_count = 0
  end

  def import
    google_service = GoogleDriveService.new(@oauth_tokens)
    transactions_data = google_service.fetch_emma_transactions(@spreadsheet_id, @sheet_name)

    Rails.logger.info "[EmmaSpreadsheetImport] Found #{transactions_data.size} transactions"

    import_transactions(transactions_data)

    Rails.logger.info "[EmmaSpreadsheetImport] Complete: #{@imported_count} imported, #{@errors.size} errors"
    @errors.empty? || @imported_count > 0
  rescue StandardError => e
    @errors << "Import failed: #{e.message}"
    Rails.logger.error "[EmmaSpreadsheetImport] #{e.message}"
    false
  end

  private

  def import_transactions(transactions_data)
    total = transactions_data.size
    @on_progress&.call(0, total)

    transactions_data.each_with_index do |row, index|
      transaction_data = parse_emma_row(row)
      next unless transaction_data

      ActiveRecord::Base.transaction do
        create_transaction(transaction_data, index + 2)
      end
      @on_progress&.call(@imported_count, total)
    end
  end

  def parse_emma_row(row)
    transaction_id = row["ID"]
    date_str = row["Date"]
    amount_str = row["Amount"]
    account_name = row["Account"]
    bank_name = row["Bank"]
    category = row["Category"]
    transaction_type = row["Type"]
    counterparty = row["Counterparty"]
    merchant = row["Merchant"]
    notes = row["Notes"]

    return if transaction_id.blank? || date_str.blank? || amount_str.blank?

    date = parse_emma_date(date_str)
    return unless date

    amount = parse_amount(amount_str)
    description = build_description(counterparty, merchant, transaction_type)
    account = "#{bank_name} #{account_name}".strip
    is_transfer = detect_transfer?(transaction_type, notes, description, category, account, counterparty, merchant)

    {
      date: date,
      description: description,
      amount: amount,
      account: account,
      transaction_id: transaction_id,
      source: "emma_export",
      category: map_category(category),
      transaction_type: transaction_type,
      is_transfer: is_transfer,
      notes: notes.presence,
      bank: bank_name.presence,
      currency: row["Currency"].presence,
      subcategory: row["Subcategory"].presence,
      tags: row["Tags"].presence,
      counterparty: counterparty.presence,
      merchant: merchant.presence,
      custom_name: row["Custom Name"].presence,
      additional_details: row["Additional details"].presence,
      linked_transaction_id: row["Linked transaction ID"].presence,
      account_name: account_name.presence,
      emma_category: category.presence
    }
  end

  def parse_emma_date(date_str)
    return if date_str.blank?

    Date.strptime(date_str, "%m/%d/%Y")
  rescue ArgumentError
    Date.parse(date_str)
  rescue ArgumentError
    Rails.logger.warn "[EmmaSpreadsheetImport] Could not parse date: #{date_str}"
    nil
  end

  def parse_amount(amount_str)
    return 0.0 if amount_str.blank?

    cleaned = amount_str.to_s.gsub(/[£$€,\s]/, "")
    Float(cleaned) rescue 0.0
  end

  def build_description(counterparty, merchant, transaction_type)
    description = merchant.presence || counterparty.presence || "Unknown"
    description = description.to_s.strip

    case transaction_type.to_s.downcase
    when "direct debit"
      "#{description} (Direct Debit)"
    else
      description
    end
  end

  def detect_transfer?(transaction_type, notes, description, category, account, counterparty, merchant)
    return true if %w[Transfer Excluded].include?(category)

    # Flex repayments: internal movements between Personal and Flex accounts
    return true if description.to_s.casecmp("flex").zero? && account.to_s.downcase.include?("monzo")

    # PayPal Credit movements: pay-later repayments and adjustments
    return true if counterparty.to_s == "PayPal Credit" && merchant.to_s == "PayPal"

    keywords = %w[transfer move money between accounts]
    text = "#{description} #{notes}".downcase
    keywords.any? { |k| text.include?(k) }
  end

  def map_category(emma_category)
    {
      "Income" => "Income",
      "Bills" => "Bills & Utilities",
      "General" => "General",
      "Food" => "Food & Dining",
      "Transport" => "Transportation",
      "Shopping" => "Shopping",
      "Entertainment" => "Entertainment",
      "Health" => "Health & Fitness",
      "Travel" => "Travel",
      "Savings" => "Savings",
      "Investments" => "Investments"
    }.fetch(emma_category) { emma_category || "Uncategorized" }
  end

  def create_transaction(transaction_data, row_number)
    transaction = Transaction.new(transaction_data)

    if transaction.save
      @imported_count += 1
    else
      error_msg = "Row #{row_number}: #{transaction.errors.full_messages.join(', ')}"
      @errors << error_msg
      Rails.logger.error "[EmmaSpreadsheetImport] #{error_msg}"
    end
  end
end
