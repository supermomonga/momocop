# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::RSpecContextTextPattern, :config do
  let(:config) do
    RuboCop::Config.new(
      'Momocop/RSpecContextTextPattern' => {
        'RequiredPattern' => '^(When|If) .+$'
      }
    )
  end

  it 'registers an offense when context text does not match pattern' do
    expect_offense(<<~RUBY)
      context 'the user is logged in' do
              ^^^^^^^^^^^^^^^^^^^^ RSpec context text must match pattern: ^(When|If) .+$
        # ...
      end
    RUBY
  end

  it 'does not register an offense when context text matches pattern' do
    expect_no_offenses(<<~RUBY)
      context 'When the user is logged in' do
        # ...
      end
    RUBY
  end

  it 'checks nested context blocks' do
    expect_offense(<<~RUBY)
      context 'When in admin panel' do
        context 'the user clicks save' do
                ^^^^^^^^^^^^^^^^^^^^ RSpec context text must match pattern: ^(When|If) .+$
          # ...
        end
      end
    RUBY
  end

  it 'does not register an offense for context without block' do
    expect_no_offenses(<<~RUBY)
      context 'Without block'
    RUBY
  end

  it 'does not register an offense for context with empty {} block' do
    expect_no_offenses(<<~RUBY)
      context('{} block') {}
    RUBY
  end

  it 'does not register an offense for context without text' do
    expect_no_offenses(<<~RUBY)
      context { }
    RUBY
  end

  context 'with custom pattern' do
    let(:config) do
      RuboCop::Config.new(
        'Momocop/RSpecContextTextPattern' => {
          'RequiredPattern' => '^Test.+'
        }
      )
    end

    it 'uses custom pattern for validation' do
      expect_no_offenses(<<~RUBY)
        context 'Test something' do
          # ...
        end
      RUBY
    end
  end
end
