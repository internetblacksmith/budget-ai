# Budgets

## Overview

Create and manage monthly spending budgets per category. Track spending against limits with visual progress bars.

## Usage

Navigate to **Budgets** in the sidebar or visit `/budgets`.

### Creating a Budget

1. Scroll to the "Add Budget" section
2. Select a category from the dropdown
3. Enter a monthly limit in pounds
4. Optionally add notes
5. Click "Create Budget"

### Viewing Budgets

Each budget card shows:
- **Category** with icon
- **Spent vs limit** amounts
- **Progress bar** — green when on track, red when over budget
- **Remaining amount** or over-budget warning
- **Percentage used**

### Editing a Budget

Each budget card has an inline edit form at the bottom to adjust the monthly limit or notes.

### Deleting a Budget

Click the delete icon on any budget card. You'll be asked to confirm.

## How Spending Is Calculated

- Only **expense** transactions (negative amounts, excluding transfers) in the **current month** are counted
- Transactions must match the budget's **category** exactly
- Income transactions in the same category are excluded

## Integration with Chat

The AI chat assistant has access to your budgets. You can:
- Ask "Suggest budgets based on my spending" for AI-recommended amounts
- Ask "Am I over budget on anything?" for a quick check
- Ask the chat to help you create budgets based on your spending patterns

## Technical Details

- **Model**: `Budget` (`app/models/budget.rb`)
- **Controller**: `BudgetsController` (`app/controllers/budgets_controller.rb`)
- **Routes**: `resources :budgets, only: [:index, :create, :update, :destroy]`
- **Database**: `budgets` table with `category` (unique), `monthly_limit`, `period_start`, `period_end`, `notes`
