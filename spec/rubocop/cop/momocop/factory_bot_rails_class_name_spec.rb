# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotRailsClassName, :config do
  let(:config) { RuboCop::Config.new }

  context 'when class option is not a symbol or string' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        factory :user, class: User.name do
        end
      RUBY
    end
  end

  context 'when class option is a symbol' do
    it 'registers offense and corrects' do
      expect_offense(<<~RUBY)
        factory(:user, class: :User) {}
                              ^^^^^ Momocop/FactoryBotRailsClassName: Use `ClassName.name` for the class option instead of a symbol, string literal, or `ClassName.to_s`.
      RUBY

      expect_correction(<<~RUBY)
        factory(:user, class: User.name) {}
      RUBY
    end
  end

  context 'when class option is a string' do
    it 'registers offense and corrects' do
      expect_offense(<<~RUBY)
        factory(:admin, class: 'Admin') {}
                               ^^^^^^^ Momocop/FactoryBotRailsClassName: Use `ClassName.name` for the class option instead of a symbol, string literal, or `ClassName.to_s`.
      RUBY

      expect_correction(<<~RUBY)
        factory(:admin, class: Admin.name) {}
      RUBY
    end
  end

  context 'when class option is a class with to_s' do
    it 'registers offense and corrects' do
      expect_offense(<<~RUBY)
        factory(:admin, class: Moderator.to_s) {}
                               ^^^^^^^^^^^^^^ Momocop/FactoryBotRailsClassName: Use `ClassName.name` for the class option instead of a symbol, string literal, or `ClassName.to_s`.
      RUBY

      expect_correction(<<~RUBY)
        factory(:admin, class: Moderator.name) {}
      RUBY
    end
  end
end
