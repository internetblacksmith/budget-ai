module ApplicationHelper
  def pattern_icon(pattern_type)
    icons = {
      weekend_spending: "weekend",
      recurring: "repeat",
      high_value: "trending_up",
      category_spike: "bar_chart"
    }

    content_tag(:span, icons[pattern_type.to_sym] || "analytics",
                class: "material-icons",
                style: "vertical-align: middle; margin-right: 8px;")
  end

  def pattern_title(pattern_type)
    titles = {
      weekend_spending: "Weekend Spending",
      recurring: "Recurring Transactions",
      high_value: "High-Value Spending",
      category_spike: "Category Spikes"
    }

    titles[pattern_type.to_sym] || "Unknown Pattern"
  end

  def pattern_description(pattern_type)
    descriptions = {
      weekend_spending: "Analyze weekend vs weekday spending patterns",
      recurring: "Identify subscription and regular payments",
      high_value: "Examine large transactions and outliers",
      category_spike: "Detect unusual spending in categories"
    }

    descriptions[pattern_type.to_sym] || "Analyze spending pattern"
  end

  def currency_amount(amount)
    amount ||= 0
    formatted_amount = "%.2f" % amount.to_f.round(2)
    "£#{formatted_amount}"
  end

  CATEGORY_ICONS = {
    "Bills" => "receipt", "Transport" => "directions_car", "Groceries" => "shopping_cart",
    "Eating out" => "restaurant", "Entertainment" => "movie", "Shopping" => "shopping_bag",
    "Personal care" => "spa", "General" => "category", "Finances" => "account_balance",
    "Income" => "payments", "Family" => "family_restroom", "Holidays" => "flight",
    "Charity" => "volunteer_activism", "Education" => "school"
  }.freeze

  def category_icon(category)
    CATEGORY_ICONS[category] || "category"
  end
end
