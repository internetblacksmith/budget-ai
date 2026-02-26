require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#pattern_icon' do
    it 'returns correct icons for all pattern types' do
      # Test all mappings in one test - these are simple lookups
      expect(helper.pattern_icon('weekend_spending')).to include('weekend')
      expect(helper.pattern_icon('recurring')).to include('repeat')
      expect(helper.pattern_icon('high_value')).to include('trending_up')
      expect(helper.pattern_icon('category_spike')).to include('bar_chart')
      expect(helper.pattern_icon('unknown')).to include('analytics') # default
    end
  end

  describe '#pattern_title' do
    it 'returns correct titles for all pattern types' do
      # Consolidated - these are simple string mappings
      titles = {
        'weekend_spending' => 'Weekend Spending',
        'recurring' => 'Recurring Transactions',
        'high_value' => 'High-Value Spending',
        'category_spike' => 'Category Spikes',
        'invalid' => 'Unknown Pattern' # default
      }

      titles.each do |pattern, expected_title|
        expect(helper.pattern_title(pattern)).to eq(expected_title)
      end
    end
  end
end
