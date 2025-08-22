# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Momocop::Helpers::RailsHelper do
  include described_class

  describe '#model_file_path' do
    it 'returns correct path for regular class name' do
      expect(model_file_path('User')).to eq('app/models/user.rb')
    end

    it 'returns correct path for namespaced class name' do
      expect(model_file_path('Admin::User')).to eq('app/models/admin/user.rb')
    end
  end

  describe '#model_file_source' do
    context 'when file exists' do
      it 'reads the file content' do
        allow(File).to receive(:exist?).with('app/models/user.rb').and_return(true)
        allow(File).to receive(:read).with('app/models/user.rb').and_return('class User; end')

        result = send(:model_file_source, 'User')
        expect(result).to eq('class User; end')
      end
    end

    context 'when file does not exist' do
      it 'returns nil' do
        allow(File).to receive(:exist?).with('app/models/user.rb').and_return(false)

        result = send(:model_file_source, 'User')
        expect(result).to be_nil
      end
    end
  end

  describe '#get_model_association_names' do
    context 'when model file exists' do
      it 'returns association names' do
        model_content = <<~RUBY
          class User < ApplicationRecord
            belongs_to :company
            belongs_to :role
            has_many :posts
          end
        RUBY

        allow(File).to receive(:exist?).with('app/models/user.rb').and_return(true)
        allow(File).to receive(:read).with('app/models/user.rb').and_return(model_content)

        result = send(:get_model_association_names, 'User')
        expect(result).to eq(%w[company role])
      end
    end

    context 'when model file does not exist' do
      it 'returns empty array' do
        allow(File).to receive(:exist?).with('app/models/user.rb').and_return(false)

        result = send(:get_model_association_names, 'User')
        expect(result).to eq([])
      end
    end
  end

  describe '#foreign_key_name' do
    it 'returns foreign key name for regular class' do
      result = send(:foreign_key_name, 'User')
      expect(result).to eq('user_id')
    end

    it 'returns foreign key name for namespaced class' do
      result = send(:foreign_key_name, 'Admin::User')
      expect(result).to eq('admin_user_id')
    end
  end
end
