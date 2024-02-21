# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotSingleDefinePerFile, :config do
  let(:config) { RuboCop::Config.new }

  context 'when file contains a single FactoryBot.define block' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
          end
          factory :admin do
          end
        end
      RUBY
    end
  end

  context 'when file contains multiple FactoryBot.define blocks' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
          end
        end
        FactoryBot.define do
        ^^^^^^^^^^^^^^^^^ Momocop/FactoryBotSingleDefinePerFile: Only one `FactoryBot.define` block is allowed per file.
          factory :admin do
          end
          factory :maintainer do
          end
        end
        FactoryBot.define
        ^^^^^^^^^^^^^^^^^ Momocop/FactoryBotSingleDefinePerFile: Only one `FactoryBot.define` block is allowed per file.
      RUBY
    end
  end
end
