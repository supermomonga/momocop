# frozen_string_literal: true

module Momocop
  # Because RuboCop doesn't yet support plugins, we have to monkey patch in a
  # bit of our configuration.
  module ConfigInjector
    def self.inject_default_config!
      path = File.expand_path(
        '../../config/default.yml',
        __dir__
      )
      hash = RuboCop::ConfigLoader.send(:load_yaml_configuration, path)
      config = RuboCop::Config.new(hash, path).tap(&:make_excludes_absolute)
      puts "configuration from #{path}" if RuboCop::ConfigLoader.debug?
      config = RuboCop::ConfigLoader.merge_with_default(config, path, unset_nil: false)
      RuboCop::ConfigLoader.instance_variable_set(:@default_configuration, config)
    end
  end
end
