# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotPropertyOrder, :config do
  let(:config) { RuboCop::Config.new }

  context 'when there are no property definitions' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
          end
        end
      RUBY
    end
  end

  describe 'association definitions' do
    context 'when block is missing' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          FactoryBot.define do
            factory(:user)
          end
        RUBY
      end
    end

    context 'has correct order' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              association(:a)
              association(:b)
            end
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
              ^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.

              association(:e)
              association(:a) {}
              ^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
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
              ^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.

              sequence(:b) { }
              a { }
              sequence(:c) { }
              ^^^^^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
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
              ^^^^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
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

    context 'has trait definition' do
      it 'registers offense and corrects by order properties' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              trait(:trait1) {}
              d
              c
              ^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
              trait(:trait2) {}
              b
              a
              ^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
              trait(:trait3) {}
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              trait(:trait1) {}
              c
              d
              trait(:trait2) {}
              a
              b
              trait(:trait3) {}
            end
          end
        RUBY
      end
    end
  end
end
