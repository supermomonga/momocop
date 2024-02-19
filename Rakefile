# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

require 'active_support/core_ext/string/inflections'
require 'erb'

desc 'Update README.md from README.md.erb'
task 'readme:update' do
  files = Dir.glob(File.join(__dir__, 'README.*.erb'))
  files.each do |src_path|
    dst_path = src_path.sub(/\.erb\z/, '')
    # ERBテンプレートの読み込み
    template = File.read(src_path)

    # ERBテンプレートのレンダリング
    renderer = ERB.new(template, trim_mode: '-')
    output = renderer.result

    # README.mdへの書き込み
    File.write(dst_path, output)
    puts "#{dst_path} has been successfully updated."
  end
end
