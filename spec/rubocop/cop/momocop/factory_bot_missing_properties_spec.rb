# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotMissingProperties, :config do
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
        belongs_to :group
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
          t.integer "team_id", null: false
          t.integer "group_id", null: false
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
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotMissingProperties: Add properties `email`, `age`, `role`.
              name { 'Name' }
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory :user, class: 'User' do
              sequence(:email) { "Email #\{_1}" }
              sequence(:age) { _1 }
              role { User.roles.keys.sample }
              name { 'Name' }
            end
          end
        RUBY
      end
    end

    context 'when block is missing' do
      it 'creates block' do
        expect_offense(<<~RUBY)
          FactoryBot.define do
            factory :user, class: 'User'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotMissingProperties: Ensure all properties of the model class are defined in the factory.
          end
        RUBY

        expect_correction(<<~RUBY)
          FactoryBot.define do
            factory :user, class: 'User' do
              sequence(:name) { "Name #\{_1}" }
              sequence(:email) { "Email #\{_1}" }
              sequence(:age) { _1 }
              role { User.roles.keys.sample }
            end
          end
        RUBY
      end
    end
  end

  describe '#model_file_path' do
    it 'returns correct file path' do
      cop = RuboCop::Cop::Momocop::FactoryBotMissingAssociations.new
      actual = cop.send(:model_file_path, 'User')
      expected = 'app/models/user.rb'

      expect(actual).to eq(expected)
    end
  end

  context 'with various column types in schema' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "articles", force: :cascade do |t|
          t.string "title", null: false
          t.text "content"
          t.date "published_date"
          t.datetime "published_at"
          t.time "publish_time"
          t.boolean "is_published"
          t.json "metadata"
          t.jsonb "settings"
          t.binary "attachment"
          t.float "price"
          t.decimal "discount"
          t.blob "file_data"
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      end
    RUBY

    before do
      mock_model_source = <<-RUBY
        class Article < ApplicationRecord
        end
      RUBY
      allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
    end

    it 'suggests appropriate property definitions for each column type' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :article, class: 'Article' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotMissingProperties: Add properties `title`, `content`, `published_date`, `published_at`, `publish_time`, `is_published`, `metadata`, `settings`, `attachment`, `price`, `discount`, `file_data`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :article, class: 'Article' do
            sequence(:title) { "Title #\{_1}" }
            sequence(:content) { "Content #\{_1}" }
            published_date { Date.today }
            published_at { Time.zone.now }
            publish_time { Time.zone.now }
            is_published { [true, false].sample }
            metadata { JSON.parse('{}') }
            settings { JSON.parse('{}') }
            attachment { }
            sequence(:price) { _1 }
            sequence(:discount) { _1 }
            file_data { }
          end
        end
      RUBY
    end
  end

  context 'when factory has no class option' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "users", force: :cascade do |t|
          t.string "name", null: false
        end
      end
    RUBY

    it 'does not register offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
            name { 'John' }
          end
        end
      RUBY
    end

    it 'does not register offense for factory with just name' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user
        end
      RUBY
    end
  end

  context 'with one-line block' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "users", force: :cascade do |t|
          t.string "name", null: false
          t.string "email", null: false
          t.datetime "created_at"
          t.datetime "updated_at"
        end
      end
    RUBY

    before do
      mock_model_source = <<-RUBY
        class User < ApplicationRecord
        end
      RUBY
      allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
    end

    it 'handles one-line block properly' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user, class: 'User' do name { 'John' } end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotMissingProperties: Add properties `email`.
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :user, class: 'User' do
            sequence(:email) { "Email #\{_1}" } name { 'John' } 
          end
        end
      RUBY
    end
  end

  context 'when factory name only (no arguments)' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "users", force: :cascade do |t|
          t.string "name", null: false
        end
      end
    RUBY

    it 'uses selector range when no arguments' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory
        end
      RUBY
    end
  end

  context 'when factory has name but no class option' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "items", force: :cascade do |t|
          t.string "name", null: false
          t.string "description"
        end
      end
    RUBY

    before do
      mock_model_source = <<-RUBY
        class Item < ApplicationRecord
        end
      RUBY
      allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
    end

    it 'marks factory name when class option is missing' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :item do
            name { 'Item' }
            description { 'Description' }
          end
        end
      RUBY
    end
  end

  context 'with factory that has only name argument and missing properties' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "widgets", force: :cascade do |t|
          t.string "name", null: false
          t.string "type"
        end
      end
    RUBY

    before do
      mock_model_source = <<-RUBY
        class Widget < ApplicationRecord
        end
      RUBY
      allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
    end
  end

  context 'with missing properties and no class option' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "products", force: :cascade do |t|
          t.string "name", null: false
          t.string "sku"
        end
      end
    RUBY

    before do
      mock_model_source = <<-RUBY
        class Product < ApplicationRecord
        end
      RUBY
      allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
    end

    it 'does not raise offense when no class option' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :product
        end
      RUBY
    end
  end

  context 'with factory selector only and missing properties' do
    include_context 'with SchemaLoader'
    let(:schema) { <<~RUBY }
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "gadgets", force: :cascade do |t|
          t.string "name", null: false
        end
      end
    RUBY

    before do
      mock_model_source = <<-RUBY
        class Gadget < ApplicationRecord
        end
      RUBY
      allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
    end

    it 'does not register offense without class option' do
      # Without class option, no offense should be registered
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :gadget
        end
      RUBY
    end
  end
end
