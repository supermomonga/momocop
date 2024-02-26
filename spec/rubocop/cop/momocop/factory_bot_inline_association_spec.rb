# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotInlineAssociation, :config do
  let(:config) { RuboCop::Config.new }

  context 'with simple association' do
    it 'registers no offense for inline association definition' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            user { association :user }
            profile { association :profile, factory: :foo }
          end
        end
      RUBY
    end

    it 'registers offense for a association method call' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            association(:user)
            ^^^^^^^^^^^ Momocop/FactoryBotInlineAssociation: Use inline association definition instead of separate `association` method call.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            user { association :user }
          end
        end
      RUBY
    end

    it 'registers offense for separate association method call' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            association(:user)
            ^^^^^^^^^^^ Momocop/FactoryBotInlineAssociation: Use inline association definition instead of separate `association` method call.
            association(:profile)
            ^^^^^^^^^^^ Momocop/FactoryBotInlineAssociation: Use inline association definition instead of separate `association` method call.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            user { association :user }
            profile { association :profile }
          end
        end
      RUBY
    end
  end

  context 'with association having options' do
    it 'registers no offense for inline association definition with options' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            user { association :user, factory: :admin }
            foo { association :bar, factory: [ :baz, :trait], prop1: 1 }
          end
        end
      RUBY
    end

    it 'registers offense for separate association method call with options' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            association(:user, factory: [:factory, :trait], prop1: 1, prop2: 2)
            ^^^^^^^^^^^ Momocop/FactoryBotInlineAssociation: Use inline association definition instead of separate `association` method call.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :blog_post do
            user { association :user, factory: [:factory, :trait], prop1: 1, prop2: 2 }
          end
        end
      RUBY
    end
  end
end
