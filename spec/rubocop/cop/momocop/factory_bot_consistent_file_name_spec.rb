# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotConsistentFileName, :config do
  let(:config) { RuboCop::Config.new }

  context 'when factory name matches the file name' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY, 'spec/factories/admin_user.rb')
        FactoryBot.define do
          factory :admin_user do
          end
        end
      RUBY

      expect_no_offenses(<<~RUBY, 'spec/factories/admin_user.rb')
        FactoryBot.define do
          factory('admin_user')
        end
      RUBY
    end
  end

  context 'when factory name does not match the file name' do
    it 'registers offense' do
      expect_offense(<<~RUBY, 'spec/factories/user.rb')
        FactoryBot.define do
          factory :admin_user do
          ^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotConsistentFileName: Factory name should match the file name.
          end
        end
      RUBY

      expect_offense(<<~RUBY, 'spec/factories/user.rb')
        FactoryBot.define do
          factory('admin_user')
          ^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotConsistentFileName: Factory name should match the file name.
        end
      RUBY
    end
  end
end
