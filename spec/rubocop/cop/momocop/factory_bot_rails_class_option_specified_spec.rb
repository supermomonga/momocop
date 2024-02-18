# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotRailsClassOptionSpecified, :config do
  let(:config) { RuboCop::Config.new }

  context 'when factory method does not specify a class option' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory(:user) { }
          ^^^^^^^ Momocop/FactoryBotRailsClassOptionSpecified: Specify a class option explicitly in FactoryBot factory.
        end
      RUBY

      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
          ^^^^^^^ Momocop/FactoryBotRailsClassOptionSpecified: Specify a class option explicitly in FactoryBot factory.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :user, class: 'User' do
          end
        end
      RUBY
    end
  end

  context 'when factory method specifies a class option' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user, class: 'User' do
          end
        end
      RUBY
    end
  end
end
