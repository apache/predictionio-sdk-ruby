require 'rubygems'
require 'rubygems/package_task'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
  s.name = "predictionio"
  s.summary = "PredictionIO Ruby SDK"
  s.description = "PredictionIO Ruby SDK"
  s.version = "0.1.0"
  s.author = "TappingStone"
  s.email = "help@tappingstone.com"
  s.homepage = "http://prediction.io"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9'
  s.files = Dir[File.join('lib', '**', '**')]
  s.has_rdoc = true
end
Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end
