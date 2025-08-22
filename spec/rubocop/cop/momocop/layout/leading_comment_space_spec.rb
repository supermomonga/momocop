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

  it 'registers an offense for comment without space' do
    expect_offense(<<~RUBY)
      #comment without space
      ^^^^^^^^^^^^^^^^^^^^^^ Momocop/Layout/LeadingCommentSpace: Missing space after `#`.
      class Foo
      end
    RUBY

    expect_correction(<<~RUBY)
      # comment without space
      class Foo
      end
    RUBY
  end

  it 'does not register an offense for comment with space' do
    expect_no_offenses(<<~RUBY)
      # comment with space
      class Foo
      end
    RUBY
  end

  it 'does not register an offense for special comments' do
    expect_no_offenses(<<~RUBY)
      #++
      # Some documentation
      #--
      class Foo
      end
    RUBY
  end

  it 'does not register an offense for shebang' do
    expect_no_offenses(<<~RUBY)
      #!/usr/bin/env ruby
      class Foo
      end
    RUBY
  end

  context 'with AllowDoxygenCommentStyle: true' do
    let(:config) do
      RuboCop::Config.new('Momocop/Layout/LeadingCommentSpace' => { 'AllowDoxygenCommentStyle' => true })
    end

    it 'does not register an offense for doxygen style comments' do
      expect_no_offenses(<<~RUBY)
        #**
        # Some comment
        #*
        class Foo
        end
      RUBY
    end
  end

  context 'with AllowGemfileRubyComment: true' do
    let(:config) do
      RuboCop::Config.new('Momocop/Layout/LeadingCommentSpace' => { 'AllowGemfileRubyComment' => true })
    end

    it 'does not register an offense for ruby version comments' do
      expect_no_offenses(<<~RUBY)
        #ruby=2.7.0
        #ruby-gemset=myproject
      RUBY
    end
  end

  it 'corrects multiple comments without space' do
    expect_offense(<<~RUBY)
      #first comment
      ^^^^^^^^^^^^^^ Momocop/Layout/LeadingCommentSpace: Missing space after `#`.
      #second comment
      ^^^^^^^^^^^^^^^ Momocop/Layout/LeadingCommentSpace: Missing space after `#`.
      class Foo
      end
    RUBY

    expect_correction(<<~RUBY)
      # first comment
      # second comment
      class Foo
      end
    RUBY
  end
end
