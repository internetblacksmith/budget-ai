require "rails_helper"

RSpec.describe TransactionEdit, type: :model do
  describe "validations" do
    it "validates presence of transaction_id" do
      edit = build(:transaction_edit, transaction_id: nil)
      expect(edit).not_to be_valid
      expect(edit.errors[:transaction_id]).to include("can't be blank")
    end

    it "validates presence of source" do
      edit = build(:transaction_edit, source: nil)
      expect(edit).not_to be_valid
      expect(edit.errors[:source]).to include("can't be blank")
    end

    it "validates uniqueness of transaction_id scoped to source" do
      create(:transaction_edit, transaction_id: "abc123", source: "emma_export")
      edit = build(:transaction_edit, transaction_id: "abc123", source: "emma_export")
      expect(edit).not_to be_valid
      expect(edit.errors[:transaction_id]).to include("has already been taken")
    end

    it "allows same transaction_id with different source" do
      create(:transaction_edit, transaction_id: "abc123", source: "emma_export")
      edit = build(:transaction_edit, transaction_id: "abc123", source: "other_source")
      expect(edit).to be_valid
    end
  end

  describe ".record_edit" do
    let!(:transaction) { create(:transaction, transaction_id: "txn-001", source: "emma_export") }

    it "creates a new edit when none exists" do
      expect {
        described_class.record_edit(transaction, { category: "Groceries" })
      }.to change(described_class, :count).by(1)

      edit = described_class.last
      expect(edit.transaction_id).to eq("txn-001")
      expect(edit.source).to eq("emma_export")
      expect(edit.category).to eq("Groceries")
    end

    it "updates an existing edit with new values" do
      described_class.record_edit(transaction, { category: "Food" })

      expect {
        described_class.record_edit(transaction, { category: "Groceries", notes: "Weekly shop" })
      }.not_to change(described_class, :count)

      edit = described_class.find_by(transaction_id: "txn-001")
      expect(edit.category).to eq("Groceries")
      expect(edit.notes).to eq("Weekly shop")
    end

    it "does not overwrite existing values with nil" do
      described_class.record_edit(transaction, { category: "Food", notes: "Important" })
      described_class.record_edit(transaction, { category: "Groceries" })

      edit = described_class.find_by(transaction_id: "txn-001")
      expect(edit.category).to eq("Groceries")
      expect(edit.notes).to eq("Important")
    end

    it "handles boolean false correctly (not treated as nil)" do
      described_class.record_edit(transaction, { is_transfer: true })
      described_class.record_edit(transaction, { is_transfer: false })

      edit = described_class.find_by(transaction_id: "txn-001")
      expect(edit.is_transfer).to be false
    end

    it "ignores non-overridable fields" do
      described_class.record_edit(transaction, { category: "Groceries", amount: 999 })

      edit = described_class.find_by(transaction_id: "txn-001")
      expect(edit.category).to eq("Groceries")
      expect(edit).not_to respond_to(:amount)
    end

    it "returns the saved edit" do
      result = described_class.record_edit(transaction, { category: "Groceries" })
      expect(result).to be_a(described_class)
      expect(result).to be_persisted
    end
  end

  describe ".bulk_record_edit" do
    let!(:txn1) { create(:transaction, transaction_id: "bulk-001") }
    let!(:txn2) { create(:transaction, transaction_id: "bulk-002") }
    let!(:txn3) { create(:transaction, transaction_id: "bulk-003") }

    it "creates edits for all transactions in the relation" do
      transactions = Transaction.where(id: [ txn1.id, txn2.id, txn3.id ])

      expect {
        described_class.bulk_record_edit(transactions, { is_transfer: true })
      }.to change(described_class, :count).by(3)

      [ txn1, txn2, txn3 ].each do |txn|
        edit = described_class.find_by(transaction_id: txn.transaction_id)
        expect(edit.is_transfer).to be true
      end
    end

    it "updates existing edits" do
      described_class.record_edit(txn1, { category: "Food" })
      transactions = Transaction.where(id: [ txn1.id, txn2.id ])

      described_class.bulk_record_edit(transactions, { category: "Groceries" })

      expect(described_class.find_by(transaction_id: txn1.transaction_id).category).to eq("Groceries")
      expect(described_class.find_by(transaction_id: txn2.transaction_id).category).to eq("Groceries")
    end
  end

  describe ".reapply_all!" do
    it "patches matching transactions with stored overrides" do
      txn = create(:transaction, transaction_id: "reapply-001", category: nil, is_transfer: false)
      create(:transaction_edit,
        transaction_id: "reapply-001",
        source: "emma_export",
        category: "Groceries",
        is_transfer: true
      )

      count = described_class.reapply_all!

      txn.reload
      expect(txn.category).to eq("Groceries")
      expect(txn.is_transfer).to be true
      expect(count).to eq(1)
    end

    it "skips edits with no matching transaction" do
      create(:transaction_edit,
        transaction_id: "orphan-001",
        source: "emma_export",
        category: "Groceries"
      )

      count = described_class.reapply_all!
      expect(count).to eq(0)
    end

    it "only applies non-nil fields" do
      txn = create(:transaction,
        transaction_id: "partial-001",
        category: "Original",
        notes: "Original note",
        is_transfer: false
      )
      create(:transaction_edit,
        transaction_id: "partial-001",
        source: "emma_export",
        category: "Updated",
        notes: nil,
        is_transfer: nil
      )

      described_class.reapply_all!

      txn.reload
      expect(txn.category).to eq("Updated")
      expect(txn.notes).to eq("Original note")
      expect(txn.is_transfer).to be false
    end

    it "correctly applies is_transfer: false override" do
      txn = create(:transaction, transaction_id: "bool-001", is_transfer: true)
      create(:transaction_edit,
        transaction_id: "bool-001",
        source: "emma_export",
        is_transfer: false
      )

      described_class.reapply_all!

      expect(txn.reload.is_transfer).to be false
    end

    it "applies description overrides" do
      txn = create(:transaction, transaction_id: "desc-001", description: "Original Desc")
      create(:transaction_edit,
        transaction_id: "desc-001",
        source: "emma_export",
        description: "Better Description"
      )

      described_class.reapply_all!

      expect(txn.reload.description).to eq("Better Description")
    end
  end

  describe "full cycle: edit → delete → reimport → reapply" do
    it "preserves edits through a database reset" do
      # 1. Create a transaction (simulating initial import)
      txn = create(:transaction,
        transaction_id: "cycle-001",
        source: "emma_export",
        category: nil,
        is_transfer: false,
        notes: nil,
        description: "TESCO STORES"
      )

      # 2. User edits the transaction
      txn.update!(category: "Groceries", is_transfer: false, notes: "Weekly shop")
      TransactionEdit.record_edit(txn, { category: "Groceries", notes: "Weekly shop" })

      # 3. Database reset (only transactions are deleted)
      Transaction.delete_all
      expect(Transaction.count).to eq(0)
      expect(TransactionEdit.count).to eq(1)

      # 4. Reimport creates the same transaction with original values
      reimported = create(:transaction,
        transaction_id: "cycle-001",
        source: "emma_export",
        category: nil,
        is_transfer: false,
        notes: nil,
        description: "TESCO STORES"
      )

      # 5. Reapply edits
      count = TransactionEdit.reapply_all!
      expect(count).to eq(1)

      # 6. Verify the edit was restored
      reimported.reload
      expect(reimported.category).to eq("Groceries")
      expect(reimported.notes).to eq("Weekly shop")
      expect(reimported.description).to eq("TESCO STORES") # Not overridden — no description edit was stored
    end
  end
end
