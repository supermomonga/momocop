# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::RSpecItWording, :config do
  let(:config) do
    RuboCop::Config.new(
      'Momocop/RSpecItWording' => {
        'RequiredPattern' => '^(should|will) .+$'
      }
    )
  end

  it 'registers an offense when it block text does not match pattern' do
    expect_offense(<<~RUBY)
      it 'does something' do
         ^^^^^^^^^^^^^^^^ RSpec it block text must match pattern: ^(should|will) .+$
        # ...
      end
    RUBY
  end

  it 'does not register an offense when it block text matches pattern' do
    expect_no_offenses(<<~RUBY)
      it 'should do something' do
        # ...
      end
    RUBY
  end

  it 'does not register an offense when it block text starts with will' do
    expect_no_offenses(<<~RUBY)
      it 'will do something' do
        # ...
      end
    RUBY
  end

  it 'does not register an offense for it without block' do
    expect_no_offenses(<<~RUBY)
      it 'should do something'
    RUBY
  end

  it 'does not register an offense for it with empty {} block' do
    expect_no_offenses(<<~RUBY)
      it('should do something') {}
    RUBY
  end

  it 'does not register an offense for it without text' do
    expect_no_offenses(<<~RUBY)
      it { }
    RUBY
  end
end
