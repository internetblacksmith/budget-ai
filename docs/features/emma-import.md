# Emma Import

Import bank transactions from Emma's Google Sheets export.

## How It Works

1. **Connect Google** - Click "Connect Google Account" on the imports page to authorise access to your Google Drive.
2. **Select Spreadsheet** - A dropdown lists all spreadsheets in your Drive. Pick the Emma export.
3. **Select Sheet** - A second dropdown appears with the sheets inside the selected spreadsheet. Pick the one containing transactions.
4. **Start Import** - Click "Start Import". The app creates an `ImportJob` and processes the sheet in the background via `EmmaSpreadsheetImportJob`.

## Technical Details

- The spreadsheet/sheet selection UI is powered by the `import-form` Stimulus controller (`app/javascript/controllers/import_form_controller.js`).
- The controller fetches data from two JSON endpoints on `ImportsController`:
  - `GET /imports/list_spreadsheets` - lists Google Drive spreadsheets
  - `GET /imports/list_spreadsheet_sheets?spreadsheet_id=ID` - lists sheets within a spreadsheet
- The import itself is a standard form POST to `POST /imports/import_emma` with `spreadsheet_id` and `sheet_name` params.
- Duplicate transactions are prevented by a unique index on `[transaction_id, source]`.

## Import Progress

After clicking "Start Import", the page shows a live progress card:
- **Pending** - "Import Queued" with an indeterminate progress bar while the job waits to start.
- **Processing** - "Importing Transactions" with a count of transactions imported so far.
- **Completed** - Green success card with the total count and a "View Transactions" link.
- **Completed with Errors** - Warning card with an expandable list of warnings.
- **Failed** - Error card with the failure message and a "Try Again" link.

Updates arrive via Turbo Streams (WebSocket). A 3-second polling fallback ensures the UI updates even if the WebSocket connection drops.

## Error Handling

When the Google token expires or the API returns an error:
- The dropdowns are hidden and an error banner is shown with the error message.
- The banner includes a **Retry** button (re-fetches without leaving the page) and a **Reconnect Google** button (starts the OAuth flow again).
- A **Reconnect** link is always visible in the account bar at the bottom of the connected section, so you can re-authenticate at any time.
- A **Disconnect** link clears the stored token and returns you to the "Connect Google Account" screen.

## Known Limitations

- Google OAuth tokens are stored in the session and may expire during long sessions. Use the Reconnect button when this happens.
- Only spreadsheets visible to the authenticated Google account are listed.
