# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotSingularFactoryName, :config do
  let(:config) { RuboCop::Config.new }

  context 'when factory names are singular' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user
          factory :admin
          factory 'status'
        end
      RUBY
    end
  end

  context 'when factory names are plural' do
    it 'registers offense and corrects to singular' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :users do end
                  ^^^^^^ Momocop/FactoryBotSingularFactoryName: Factory name should be singular, not plural.
          factory('admins') {}
                  ^^^^^^^^ Momocop/FactoryBotSingularFactoryName: Factory name should be singular, not plural.
          factory "statuses"
                  ^^^^^^^^^^ Momocop/FactoryBotSingularFactoryName: Factory name should be singular, not plural.
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :user do end
          factory('admin') {}
          factory "status"
        end
      RUBY
    end
  end
end
