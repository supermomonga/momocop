# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::Layout::LeadingCommentSpace, :config do
  let(:config) { RuboCop::Config.new }

  it 'does not register an offense for #:' do
    expect_no_offenses(<<~RUBY)
      class Foo
        attr_reader :name #: String
      end
    RUBY
  end
end
