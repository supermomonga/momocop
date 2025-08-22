# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Momocop::ConfigInjector do
  describe '.inject_default_config!' do
    let(:debug_mode) { false }

    before do
      @original_default = RuboCop::ConfigLoader.instance_variable_get(:@default_configuration)
      allow(RuboCop::ConfigLoader).to receive(:debug?).and_return(debug_mode)
    end

    after do
      RuboCop::ConfigLoader.instance_variable_set(:@default_configuration, @original_default)
    end

    context 'when debug mode is enabled' do
      let(:debug_mode) { true }

      it 'outputs configuration path to stdout' do
        expect { described_class.inject_default_config! }.to output(/configuration from/).to_stdout
      end
    end

    context 'when debug mode is disabled' do
      let(:debug_mode) { false }

      it 'does not output configuration path' do
        expect { described_class.inject_default_config! }.not_to output.to_stdout
      end
    end

    it 'loads the default configuration' do
      described_class.inject_default_config!

      config = RuboCop::ConfigLoader.instance_variable_get(:@default_configuration)
      expect(config).to be_a(RuboCop::Config)
    end

    it 'loads configuration from the correct path' do
      expected_path = File.expand_path('../../config/default.yml', __dir__)

      expect(RuboCop::ConfigLoader).to receive(:send).with(:load_yaml_configuration, expected_path).and_call_original

      described_class.inject_default_config!
    end

    it 'merges with default configuration' do
      expect(RuboCop::ConfigLoader).to receive(:merge_with_default).and_call_original

      described_class.inject_default_config!
    end

    it 'makes excludes absolute' do
      config_double = instance_double(RuboCop::Config)
      allow(RuboCop::Config).to receive(:new).and_return(config_double)
      allow(config_double).to receive(:make_excludes_absolute)
      allow(RuboCop::ConfigLoader).to receive(:merge_with_default).and_return(config_double)

      described_class.inject_default_config!

      expect(config_double).to have_received(:make_excludes_absolute)
    end
  end
end
