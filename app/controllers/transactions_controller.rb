class TransactionsController < ApplicationController
  def index
    @transactions = Transaction.all

    apply_show_filter
    apply_account_filter
    apply_category_filter
    apply_search_filter
    apply_amount_filter

    @filtered_transactions = @transactions.order(date: :desc)

    @total_income = @filtered_transactions.actual_income.sum(:amount)
    @total_expenses = @filtered_transactions.actual_expenses.sum(:amount).abs
    @net_balance = @total_income - @total_expenses
    @filtered_count = @filtered_transactions.count

    per_page = [ (params[:per] || 200).to_i, 500 ].min
    @transactions = @filtered_transactions.page(params[:page]).per(per_page)

    @accounts = Transaction.distinct.pluck(:account).compact.sort
    @categories = Transaction.where.not(category: [ nil, "" ]).distinct.pluck(:category).sort

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @transaction = Transaction.find(params[:id])
  end

  def new
    @transaction = Transaction.new(date: Date.current)
    @accounts = Account.pluck(:name).sort
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.transaction_id = "manual-#{SecureRandom.hex(8)}"
    @transaction.source = "emma_export"

    if @transaction.save
      redirect_to transactions_path, notice: "Transaction was successfully created."
    else
      @accounts = Account.pluck(:name).sort
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @transaction = Transaction.find(params[:id])
    @accounts = Account.pluck(:name).sort
  end

  def update
    @transaction = Transaction.find(params[:id])

    if @transaction.update(transaction_params)
      TransactionEdit.record_edit(@transaction, transaction_params.to_h.symbolize_keys)
      redirect_to transaction_path(@transaction), notice: "Transaction was successfully updated."
    else
      @accounts = Account.pluck(:name).sort
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  def bulk_update
    transaction_ids = params[:transaction_ids].is_a?(String) ?
      params[:transaction_ids].split(",").map(&:to_i) :
      params[:transaction_ids] || []

    action = params[:bulk_action]

    if transaction_ids.empty?
      redirect_to transactions_path, alert: "No transactions selected."
      return
    end

    transactions = Transaction.where(id: transaction_ids)
    transaction_count = transactions.count

    case action
    when "mark_transfer"
      TransactionEdit.bulk_record_edit(transactions, { is_transfer: true })
      transactions.update_all(is_transfer: true)
      redirect_to transactions_path, notice: "#{transaction_count} transactions marked as transfers."
    when "unmark_transfer"
      TransactionEdit.bulk_record_edit(transactions, { is_transfer: false })
      transactions.update_all(is_transfer: false)
      redirect_to transactions_path, notice: "#{transaction_count} transactions unmarked as transfers."
    when "delete"
      transactions.destroy_all
      redirect_to transactions_path, notice: "#{transaction_count} transactions deleted."
    when "categorize"
      if params[:category].present?
        TransactionEdit.bulk_record_edit(transactions, { category: params[:category] })
        transactions.update_all(category: params[:category])
        redirect_to transactions_path, notice: "#{transaction_count} transactions categorized as #{params[:category]}."
      else
        redirect_to transactions_path, alert: "Please select a category."
      end
    else
      redirect_to transactions_path, alert: "Invalid bulk action."
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:date, :description, :amount, :category, :account, :notes, :is_transfer)
  end

  def apply_show_filter
    case params[:show]
    when "income"
      @transactions = @transactions.actual_income
    when "expenses"
      @transactions = @transactions.actual_expenses
    when "transfers"
      @transactions = @transactions.transfers
    when "all"
      # No filter — show everything including transfers
    else
      # Default: exclude transfers
      @transactions = @transactions.non_transfers
    end
  end

  def apply_account_filter
    return unless params[:account].present?

    @transactions = @transactions.by_account(params[:account])
  end

  def apply_category_filter
    return unless params[:category].present?

    @transactions = @transactions.where(category: params[:category])
  end

  def apply_search_filter
    return unless params[:search].present?

    @transactions = @transactions.where("description LIKE ?", "%#{params[:search]}%")
  end

  def apply_amount_filter
    return unless params[:amount].present?

    amount_value = params[:amount].to_f.abs
    @transactions = @transactions.where("ABS(amount) = ?", amount_value)
  end
end
