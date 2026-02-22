# Testing Guide

## Running Tests

```bash
# Full test suite
make test

# RSpec only
bundle exec rspec --format documentation

# Cucumber only
bundle exec cucumber

# Specific file
bundle exec rspec spec/services/emma_spreadsheet_import_service_spec.rb

# Coverage report
bundle exec rspec && open coverage/index.html
```

## Test Structure

- `spec/models/` - Model validation and business logic
- `spec/services/` - Service objects (import, LLM, Google Drive)
- `spec/requests/` - Controller/API request specs
- `spec/helpers/` - View helper specs
- `spec/mcp/` - MCP tool specs
- `features/` - Cucumber integration scenarios

## Writing Tests

- Use factories (FactoryBot) instead of fixtures
- Test both happy paths and edge cases
- Minimum 80% coverage required
- All tests must pass before committing

## Quick Verification

```bash
make commit-check  # Runs everything: tests + lint + coverage
```
