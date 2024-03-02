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

  context 'when there is only one property' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
            a
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

        expect_no_offenses(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              a { association(:a) }
              b { association(:b) }
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

              e { association(:e) }
              a { association(:a) {} }
              ^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              association(:b)
              association(:c) {}
              association(:d) {}

              a { association(:a) {} }
              e { association(:e) }
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

              sequence(:b) { "b #\{_1}" }
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
              sequence(:b) { "b #\{_1}" }
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
              d {
                :d
              }
              sequence(:e)
              association(:f)
              b {
                :b
              }
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
              b {
                :b
              }
              d {
                :d
              }
              sequence(:e)
            end
          end
        RUBY
      end
    end

    context 'has comment' do
      it 'registers offense and corrects by order properties' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              b
              # a
              a
              ^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              # a
              a
              b
            end
          end
        RUBY
      end
    end

    context 'has comment' do
      it 'registers offense and corrects by order properties' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              # d
              d
              c
              # b
              b { }
              # a1
              # a2
              a
              ^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.

              ab
              aa
              ^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory(:user) do
              # a1
              # a2
              a
              # b
              b { }
              c
              # d
              d

              aa
              ab
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

    describe 'inline association' do
      context 'with single-statements block' do
        it 'recognize as association' do
          expect_offense(<<~RUBY)
            FactoryBot.define do
              factory(:user) do
                a
                b { association(:b) }
                ^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
              end
            end
          RUBY

          expect_correction(<<~RUBY)
            FactoryBot.define do
              factory(:user) do
                b { association(:b) }
                a
              end
            end
          RUBY
        end
      end

      context 'with multi-statements block' do
        it 'recognize as association' do
          expect_offense(<<~RUBY)
            FactoryBot.define do
              factory(:user) do
                a
                b { nil || association(:b) }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotPropertyOrder: Sort properties and associations alphabetically.
              end
            end
          RUBY

          expect_correction(<<~RUBY)
            FactoryBot.define do
              factory(:user) do
                b { nil || association(:b) }
                a
              end
            end
          RUBY
        end
      end
    end
  end
end
