# Contributing to Budget AI 🤝

First off, thank you for considering contributing to Budget AI! It's people like you that make Budget AI such a great tool for the personal finance community.

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Show empathy towards other community members

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Great Bug Reports Include:**
- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Screenshots if applicable
- Your environment details (OS, Ruby version, etc.)
- Any relevant error messages or logs

**Bug Report Template:**
```markdown
## Description
Brief description of the bug

## Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., macOS 14.0]
- Ruby: [e.g., 3.4.2]
- Rails: [e.g., 8.0.2]
- Browser: [e.g., Chrome 120]
```

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- Use a clear and descriptive title
- Provide a detailed description of the proposed enhancement
- Include mockups or examples if applicable
- Explain why this enhancement would be useful
- List any alternative solutions you've considered

### 🔀 Pull Requests

1. **Fork the Repository**
```bash
# Fork via GitHub UI, then:
git clone https://github.com/YOUR_USERNAME/budget-ai.git
cd budget-ai
git remote add upstream https://github.com/your-org/budget-ai.git
```

2. **Create a Feature Branch**
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number-description
```

3. **Make Your Changes**
- Write clean, maintainable code
- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

4. **Commit Your Changes**
```bash
# Use clear, descriptive commit messages
git commit -m "Add feature: description of what you added"
# or
git commit -m "Fix #123: description of what you fixed"
```

5. **Run Tests**
```bash
# Run all tests
make test

# Run specific tests
bundle exec rspec spec/path/to/test_spec.rb
bundle exec cucumber features/your_feature.feature

# Check code style
bundle exec rubocop

# Check test coverage
make coverage
```

6. **Push and Create PR**
```bash
git push origin feature/your-feature-name
```
Then create a Pull Request via GitHub UI.

## Development Setup

### 1. Install Dependencies
```bash
bundle install
npm install  # If working on JavaScript
```

### 2. Setup Database
```bash
rails db:create
rails db:migrate
rails db:seed  # For demo data
```

### 3. Run Development Server
```bash
bin/dev  # Runs server with hot reload
```

### 4. Run Tests
```bash
# All tests
make test

# Unit tests only
bundle exec rspec

# Integration tests only
bundle exec cucumber

# With coverage
COVERAGE=true bundle exec rspec
```

## Coding Standards

### Ruby Style Guide

We follow the Ruby community style guide with some modifications:

```ruby
# Good
class TransactionService
  def process_import(file)
    validate_file(file)
    transactions = parse_file(file)
    save_transactions(transactions)
  end

  private

  def validate_file(file)
    raise ArgumentError, "File is required" unless file.present?
    raise ArgumentError, "Invalid file type" unless valid_file_type?(file)
  end
end

# Bad
class transaction_service
  def ProcessImport(file)
    if !file
      return false
    end
    # ...
  end
end
```

### Testing Standards

**Every PR Must Include:**
- Unit tests for new functionality
- Integration tests for user-facing features
- Updated tests for modified functionality
- Minimum 85% code coverage maintained

**Test Example:**
```ruby
RSpec.describe TransactionService do
  describe '#process_import' do
    let(:service) { described_class.new }
    let(:valid_file) { fixture_file_upload('transactions.csv') }

    context 'with valid file' do
      it 'imports transactions successfully' do
        expect { service.process_import(valid_file) }
          .to change(Transaction, :count).by(10)
      end
    end

    context 'with invalid file' do
      it 'raises an error' do
        expect { service.process_import(nil) }
          .to raise_error(ArgumentError, /File is required/)
      end
    end
  end
end
```

### Documentation Standards

- Add inline comments for complex logic
- Update README for new features
- Document new configuration options
- Add user guides for new functionality
- Include API documentation for new endpoints

### Commit Message Guidelines

```
Type: Brief description (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain the problem this commit solves and why.

- Bullet points for multiple changes
- Keep each point concise

Fixes #123
Refs #456
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions or corrections
- `chore:` Maintenance tasks

## Quality Checklist

Before submitting a PR, ensure:

- [ ] **Tests Pass**: All tests are green
- [ ] **Coverage**: Test coverage ≥ 85%
- [ ] **Rubocop**: No style violations
- [ ] **Documentation**: Updated as needed
- [ ] **Commits**: Clean, descriptive messages
- [ ] **Branch**: Up to date with main
- [ ] **Review**: Self-reviewed your changes

## Pull Request Process

1. **Update Documentation** - Ensure README and docs reflect your changes
2. **Add Tests** - Include tests that demonstrate your fix/feature works
3. **Update CHANGELOG** - Note your changes in the unreleased section
4. **Pass CI** - Ensure all GitHub Actions checks pass
5. **Code Review** - Address reviewer feedback promptly
6. **Squash & Merge** - We use squash merging to keep history clean

## Project Structure

```
budget-ai/
├── app/
│   ├── controllers/    # Request handling
│   ├── models/         # Data models
│   ├── services/       # Business logic
│   ├── views/          # Templates
│   └── javascript/     # Frontend code
├── config/             # Configuration
├── db/                 # Database files
├── docs/               # Documentation
├── spec/               # RSpec tests
├── features/           # Cucumber tests
└── lib/                # Libraries
```

## Where to Get Help

- **Documentation**: Read through our [docs](docs/)
- **Discord**: Join our community chat
- **Issues**: Check existing [issues](https://github.com/your-org/budget-ai/issues)
- **Discussions**: Ask in [discussions](https://github.com/your-org/budget-ai/discussions)

## Recognition

Contributors are recognized in:
- The README contributors section
- Release notes
- The AUTHORS file
- Special mentions for significant contributions

## Financial Contributions

While we don't accept monetary donations, you can support the project by:
- Contributing code
- Improving documentation
- Helping other users
- Spreading the word

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Budget AI! 🎉

Your efforts help make personal finance management accessible and private for everyone.