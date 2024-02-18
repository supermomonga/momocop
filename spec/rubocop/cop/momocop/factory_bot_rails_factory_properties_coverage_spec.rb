# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotRailsFactoryPropertiesCoverage, :config do
  let(:config) { RuboCop::Config.new }

  before do
    version = RUBY_VERSION[..-3].to_f
    allow_any_instance_of(described_class).to receive(:target_ruby_version).and_return(version)

    # mock model file source
    mock_model_source = <<-RUBY
      class User < ApplicationRecord
        belongs_to :account
        belongs_to :profile, foreign_key: :user_profile_id
        belongs_to :team, class_name: 'Organization'
        enum :role, { user: 0, admin: 1 }
      end
    RUBY
    allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
  end

  context 'with db/schema.rb' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "accounts", force: :cascade do |t|
          t.string "account_number", null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end

        create_table "users", force: :cascade do |t|
          t.string "name", null: false
          t.string "email", null: false
          t.integer "age", null: false
          t.integer "role", default: 0, null: false
          t.references "account", foreign_key: true
          t.integer "user_profile_id", null: false
          t.integer "organization_id", null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      end
    RUBY

    context 'when a factory defines all model properties' do
      it 'registers no offense' do
        expect_no_offenses(<<~RUBY)
          FactoryBot.define do
            factory :user, class: 'User' do
              name { 'John Doe' }
              email { 'john@example.com' }
              age { 30 }
              role { User.roles.keys.sample }
            end
          end
        RUBY
      end
    end

    context 'when a factory does not define all model properties' do
      it 'registers offense and corrects by adding missing properties' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory :user, class: 'User' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotRailsFactoryPropertiesCoverage: Ensure all properties of the model class are defined in the factory.
              name { 'Name' }
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory :user, class: 'User' do
              sequence(:age) { _1 }
              sequence(:email) { "Email #\{_1}" }
              role { User.roles.keys.sample }
              name { 'Name' }
            end
          end
        RUBY
      end
    end
  end

  describe '#model_file_path' do
    it 'returns correct file path' do
      cop = RuboCop::Cop::Momocop::FactoryBotRailsFactoryAssociationsCoverage.new
      actual = cop.send(:model_file_path, 'User')
      expected = 'app/models/user.rb'

      expect(actual).to eq(expected)
    end
  end
end
