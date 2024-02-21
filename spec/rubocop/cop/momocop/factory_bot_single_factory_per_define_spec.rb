# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotSingleFactoryPerDefine, :config do
  let(:config) { RuboCop::Config.new }

  context 'when file contains a single top-level factory' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
          end
        end
        FactoryBot.define do
          factory :profile do
          end
        end
      RUBY
    end

    it 'registers no offense for nested factories' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          foo
          factory :user do
            name { 'Name' }
            factory :admin_user do
            end
            bar
          end
        end
      RUBY
    end
  end

  context 'when file contains multiple top-level factories' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
          end
          factory :profile do
          ^^^^^^^^^^^^^^^^ Momocop/FactoryBotSingleFactoryPerDefine: Only one top-level factory is allowed per FactoryBot.define.
          end
        end
      RUBY
    end

    it 'registers offenses for each factory beyond the first' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
            factory :admin_user do
            end
            factory :moderator_user
          end
          factory :profile do
          ^^^^^^^^^^^^^^^^ Momocop/FactoryBotSingleFactoryPerDefine: Only one top-level factory is allowed per FactoryBot.define.
            factory :disposed_profile
          end
          factory :account
          ^^^^^^^^^^^^^^^^ Momocop/FactoryBotSingleFactoryPerDefine: Only one top-level factory is allowed per FactoryBot.define.
        end
      RUBY
    end
  end
end
