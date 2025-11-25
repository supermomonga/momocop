# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::RbiMissingExtendTSig, :config do
  let(:config) { RuboCop::Config.new }

  context 'when sig is used without extending T::Sig' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        class User
        ^^^^^ Momocop/RbiMissingExtendTSig: Add `extend T::Sig` when using `sig` to type methods.
          sig { void }
          def call; end
        end
      RUBY

      expect_correction(<<~RUBY)
        class User
          extend T::Sig
          sig { void }
          def call; end
        end
      RUBY
    end
  end

  context 'when sig and def are separated by a blank line' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        module User
          sig { void }

          def call; end
        end
      RUBY
    end
  end

  context 'when sig is not a block call' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class User
          sig(:void)
          def call; end
        end
      RUBY
    end
  end

  context 'when T::Sig is already extended' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class User
          extend T::Sig

          sig { void }
          def call; end
        end
      RUBY
    end
  end

  context 'when the only statement is extend T::Sig' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class User
          extend T::Sig
        end
      RUBY
    end
  end

  context 'when class is defined on a single line' do
    it 'does not register an offense when sig is not on the preceding line' do
      expect_no_offenses(<<~RUBY)
        class User; sig { void }; def call; end; end
      RUBY
    end
  end

  context 'when module uses sig' do
    it 'adds extend T::Sig to the module' do
      expect_offense(<<~RUBY)
        module Service
        ^^^^^^ Momocop/RbiMissingExtendTSig: Add `extend T::Sig` when using `sig` to type methods.
          sig { void }
          def call; end
        end
      RUBY

      expect_correction(<<~RUBY)
        module Service
          extend T::Sig
          sig { void }
          def call; end
        end
      RUBY
    end
  end

  context 'when sig is at top-level' do
    it 'adds extend T::Sig at the top of the file' do
      expect_offense(<<~RUBY)
        sig { void }
        ^^^ Momocop/RbiMissingExtendTSig: Add `extend T::Sig` when using `sig` to type methods.
        def call; end
      RUBY

      expect_correction(<<~RUBY)
        extend T::Sig
        sig { void }
        def call; end
      RUBY
    end

    it 'does not register an offense when extend T::Sig already exists' do
      expect_no_offenses(<<~RUBY)
        extend T::Sig
        sig { void }
        def call; end
      RUBY
    end
  end

  context 'when sig block is multi-line' do
    it 'adds extend T::Sig and keeps the block body intact' do
      expect_offense(<<~RUBY)
        class User
        ^^^^^ Momocop/RbiMissingExtendTSig: Add `extend T::Sig` when using `sig` to type methods.
          sig do
            params(a: Integer)
              .returns(Integer)
          end
          def call(a); end
        end
      RUBY

      expect_correction(<<~RUBY)
        class User
          extend T::Sig
          sig do
            params(a: Integer)
              .returns(Integer)
          end
          def call(a); end
        end
      RUBY
    end
  end

  context 'when nested classes and only middle class has sig' do
    it 'only corrects the class that uses sig' do
      expect_offense(<<~RUBY)
        class Foo
          class Bar
          ^^^^^ Momocop/RbiMissingExtendTSig: Add `extend T::Sig` when using `sig` to type methods.
            sig { void }
            def call; end
          end

          class Baz
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          class Bar
            extend T::Sig
            sig { void }
            def call; end
          end

          class Baz
          end
        end
      RUBY
    end
  end

  context 'when deeply nested class under the class with sig' do
    it 'adds extend T::Sig only to the class that uses sig' do
      expect_offense(<<~RUBY)
        class Foo
          class Bar
          ^^^^^ Momocop/RbiMissingExtendTSig: Add `extend T::Sig` when using `sig` to type methods.
            sig { void }
            def call; end

            class Baz
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          class Bar
            extend T::Sig
            sig { void }
            def call; end

            class Baz
            end
          end
        end
      RUBY
    end
  end
end
