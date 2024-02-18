# frozen_string_literal: true

require_relative 'lib/momocop/version'

Gem::Specification.new do |spec|
  spec.name = 'momocop'
  spec.version = Momocop::VERSION
  spec.authors = ['supermomonga']
  spec.email = ['hi@supermomonga.com']

  spec.summary = 'Convention focused opinionated custom cops for RuboCop.'
  spec.description = 'Convention focused opinionated custom cops for RuboCop.'
  spec.homepage = 'https://github.com/supermomonga/momocop'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"

  spec.files = Dir.chdir(__dir__) {
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'rubocop'
  spec.add_runtime_dependency 'rubocop-rails'
  spec.add_runtime_dependency 'sevencop'
end
