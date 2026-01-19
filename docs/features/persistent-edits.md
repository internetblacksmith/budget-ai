# Persistent Transaction Edits

Manual edits to transactions (category, transfer flag, notes, description) survive database resets and reimports.

## Problem

When the database is reset and transactions are reimported from Emma, all manual edits are lost because `reset_database` calls `Transaction.delete_all`.

## How It Works

1. **Edit recording** - Every time a transaction is edited (via the UI, LLM categorisation, or MCP tools), the change is written to both the `transactions` table and a separate `transaction_edits` table.
2. **Reset survival** - The `transaction_edits` table is keyed by `transaction_id + source` (the Emma-assigned ID, not the Rails primary key) and is **not** touched by `reset_database`.
3. **Automatic reapply** - After every successful Emma import, `TransactionEdit.reapply_all!` patches matching transactions in-place using `update_columns`.

## What Gets Persisted

| Field | Persisted? |
|-------|-----------|
| `category` | Yes |
| `is_transfer` | Yes |
| `notes` | Yes |
| `description` | Yes |

Only non-nil values are stored. Setting `is_transfer: false` is correctly treated as an override (not ignored).

## Where Edits Are Recorded

- `TransactionsController#update` - single transaction edit form
- `TransactionsController#bulk_update` - mark/unmark transfer, bulk categorise
- `InsightsController#categorize_transactions` - LLM auto-categorisation
- `CategorizeTransactionTool` - MCP tool for setting category
- `AddNoteTool` - MCP tool for adding notes

## Where Edits Are Reapplied

- `EmmaSpreadsheetImportJob#finalize_import` - called after every successful import

## Technical Details

- **Model**: `TransactionEdit` (`app/models/transaction_edit.rb`)
- **Table**: `transaction_edits` with unique index on `[transaction_id, source]`
- **No foreign key** to `transactions` - the whole point is surviving deletes
- **Key methods**:
  - `.record_edit(transaction, attrs)` - create or update an edit record
  - `.bulk_record_edit(transactions_relation, attrs)` - record edits for multiple transactions
  - `.reapply_all!` - find each edit, match to a transaction, apply non-nil fields
