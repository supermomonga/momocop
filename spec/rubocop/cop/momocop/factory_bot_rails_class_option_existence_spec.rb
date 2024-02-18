# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotRailsClassOptionExistence, :config do
  let(:config) { RuboCop::Config.new }

  context 'when class option is not a symbol or string' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        factory :user do
        end
      RUBY

      expect_no_offenses(<<~RUBY)
        factory :user, class: User.name do
        end
      RUBY
    end
  end

  context 'when the class exists' do
    before do
      allow_any_instance_of(described_class).to receive(:class_exists?).and_return(true)
    end

    context 'when class option is a symbol' do
      it 'registers offense and corrects' do
        expect_no_offenses(<<~RUBY)
          factory(:user, class: :User) {}
        RUBY
      end
    end

    context 'when the class option is a string' do
      it 'registers offense and corrects' do
        expect_no_offenses(<<~RUBY)
          factory(:admin, class: 'User') {}
        RUBY
      end
    end
  end

  context 'when class not exists' do
    context 'when class option is a symbol' do
      it 'registers offense and corrects' do
        expect_offense(<<~RUBY)
          factory(:user, class: :User) {}
                                ^^^^^ Momocop/FactoryBotRailsClassOptionExistence: Specified class does not exist. Please make sure that the class exists.
        RUBY
      end
    end

    context 'when class option is a string' do
      it 'registers offense and corrects' do
        expect_offense(<<~RUBY)
          factory(:admin, class: 'User') {}
                                 ^^^^^^ Momocop/FactoryBotRailsClassOptionExistence: Specified class does not exist. Please make sure that the class exists.
        RUBY
      end
    end
  end
end
