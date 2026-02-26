# frozen_string_literal: true

class DashboardController < ApplicationController
  DONUT_COLORS = %w[#00e5a0 #ff6b6b #a78bfa #fbbf24 #38bdf8].freeze
  def index
    today = Date.current
    @current_month_label = today.strftime("%B %Y")

    @total_income = Transaction.non_transfers.income.sum(:amount)
    @total_expenses = Transaction.non_transfers.expenses.sum(:amount).abs
    @net_balance = @total_income - @total_expenses
    @savings_rate = @total_income.positive? ? ((@net_balance / @total_income) * 100).round : 0

    @monthly_data = build_monthly_data(today)
    @top_categories = build_top_categories
    @recent_transactions = Transaction.non_transfers.order(date: :desc, created_at: :desc).limit(5)
  end

  private

  def build_monthly_data(today)
    6.times.map do |i|
      month_start = (today - i.months).beginning_of_month
      month_end = month_start.end_of_month
      range = Transaction.non_transfers.by_date_range(month_start, month_end)

      {
        month: month_start.strftime("%b"),
        income: range.actual_income.sum(:amount),
        expenses: range.actual_expenses.sum(:amount).abs
      }
    end.reverse
  end

  def build_top_categories
    category_totals = Transaction.non_transfers.expenses
      .group(:category)
      .sum(:amount)
      .transform_values(&:abs)
      .sort_by { |_, v| -v }
      .first(5)

    grand_total = category_totals.sum { |_, v| v }

    offset = 25
    category_totals.each_with_index.map do |(name, amount)|
      pct = grand_total.positive? ? ((amount / grand_total) * 100).round : 0
      dash = (pct.to_f / 100) * 100
      color = DONUT_COLORS[category_totals.index([ name, amount ]) || 0]
      icon = helpers.category_icon(name)

      entry = { name: name || "Uncategorised", amount: amount, pct: pct,
                dash: dash, gap: 100 - dash, offset: offset, color: color, icon: icon }
      offset -= dash
      entry
    end
  end
end
