# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::RSpecDescribeTextPattern, :config do
  let(:config) do
    RuboCop::Config.new(
      'Momocop/RSpecDescribeTextPattern' => {
        'AllowedPattern' => '.+こと$'
      }
    )
  end

  it 'registers an offense when describe text does not match pattern' do
    expect_offense(<<~RUBY)
      describe 'ユーザーを作成する' do
               ^^^^^^^^^^^^^^^^^^^ RSpec describe のテキストは「.+こと$」にマッチする必要があります
        # ...
      end
    RUBY
  end

  it 'does not register an offense when describe text matches pattern' do
    expect_no_offenses(<<~RUBY)
      describe 'ユーザーを作成すること' do
        # ...
      end
    RUBY
  end

  it 'checks nested describe blocks' do
    expect_offense(<<~RUBY)
      describe 'ユーザー管理すること' do
        describe 'ユーザーを作成する' do
                 ^^^^^^^^^^^^^^^^^^^ RSpec describe のテキストは「.+こと$」にマッチする必要があります
          # ...
        end
      end
    RUBY
  end

  context 'with custom pattern' do
    let(:config) do
      RuboCop::Config.new(
        'Momocop/RSpecDescribeTextPattern' => {
          'AllowedPattern' => '^Test.+'
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
