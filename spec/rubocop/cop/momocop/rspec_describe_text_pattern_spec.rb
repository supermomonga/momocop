# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::RSpecDescribeTextPattern, :config do
  let(:config) do
    RuboCop::Config.new(
      'Momocop/RSpecDescribeTextPattern' => {
        'RequiredPattern' => '^(?!When ).+'
      }
    )
  end

  it 'registers an offense when describe text does not match pattern' do
    expect_offense(<<~RUBY)
      describe 'When user creates something' do
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpec describe text must match pattern: ^(?!When ).+
        # ...
      end
    RUBY
  end

  it 'does not register an offense when describe text matches pattern' do
    expect_no_offenses(<<~RUBY)
      describe 'A user creates something' do
        # ...
      end
    RUBY
  end

  it 'checks nested describe blocks' do
    expect_offense(<<~RUBY)
      describe 'A user management' do
        describe 'When creating user' do
                 ^^^^^^^^^^^^^^^^^^^^ RSpec describe text must match pattern: ^(?!When ).+
          # ...
        end
      end
    RUBY
  end

  it 'does not register an offense for describe without block' do
    expect_no_offenses(<<~RUBY)
      describe 'Without block'
    RUBY
  end

  it 'does not register an offense for describe with empty {} block' do
    expect_no_offenses(<<~RUBY)
      describe('{} block') {}
    RUBY
  end

  context 'with custom pattern' do
    let(:config) do
      RuboCop::Config.new(
        'Momocop/RSpecDescribeTextPattern' => {
          'RequiredPattern' => '^Test.+'
        }
      )
    end

    it 'uses custom pattern for validation' do
      expect_no_offenses(<<~RUBY)
        describe 'Test something' do
          # ...
        end
      RUBY
    end
  end
end
