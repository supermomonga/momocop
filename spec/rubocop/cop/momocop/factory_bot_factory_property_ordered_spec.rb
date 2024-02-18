# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotFactoryPropertyOrdered, :config do
  let(:config) { RuboCop::Config.new }

  context 'when there are no property definitions' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        factory :user do
        end
      RUBY
    end
  end

  describe 'association definitions' do
    context 'has correct order' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          factory(:user) do
            association(:a)
            association(:b)
          end
        RUBY
      end
    end

    context 'has incorrect order' do
      it 'registers offense and corrects by order properties' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              association(:d) {}
              association(:b)
              association(:c) {}
              ^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotFactoryPropertyOrdered: Sort properties and associations alphabetically.

              association(:e)
              association(:a) {}
              ^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotFactoryPropertyOrdered: Sort properties and associations alphabetically.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              association(:b)
              association(:c) {}
              association(:d) {}

              association(:a) {}
              association(:e)
            end
          end
        RUBY
      end
    end
  end

  describe 'property definitions' do
    context 'has correct order' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          factory(:user) do
            sequence(:a) { }
            b { }
            sequence(:c) { }
            d { }
          end
        RUBY

        expect_no_offenses(<<~RUBY)
          factory(:user) do
            c {}
            d {}

            a {}
            b {}
          end
        RUBY
      end
    end

    context 'has incorrect order' do
      it 'registers offense and corrects by order properties' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              sequence(:e)
              f
              sequence(:d)
              ^^^^^^^^^^^^ Momocop/FactoryBotFactoryPropertyOrdered: Sort properties and associations alphabetically.

              sequence(:b) { }
              a { }
              sequence(:c) { }
              ^^^^^^^^^^^^^^^^ Momocop/FactoryBotFactoryPropertyOrdered: Sort properties and associations alphabetically.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              sequence(:d)
              sequence(:e)
              f

              a { }
              sequence(:b) { }
              sequence(:c) { }
            end
          end
        RUBY
      end
    end
  end

  describe 'association and property definitions' do
    context 'has correct order' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          factory(:user) do
            association(:c)
            sequence(:a)
            b { }
          end
        RUBY
      end
    end

    context 'has incorrect order' do
      it 'registers offense and corrects by order properties' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              d { }
              sequence(:e)
              association(:f)
              b { }
              sequence(:a)
              association(:c)
              ^^^^^^^^^^^^^^^ Momocop/FactoryBotFactoryPropertyOrdered: Sort properties and associations alphabetically.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              association(:c)
              association(:f)
              sequence(:a)
              b { }
              d { }
              sequence(:e)
            end
          end
        RUBY
      end
    end
  end
end
