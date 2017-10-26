$:.push File.expand_path('../lib', __FILE__)
require 'predictionio/version'

Gem::Specification.new do |s|
  s.name = 'predictionio'
  s.summary = 'PredictionIO Ruby SDK'
  s.description = <<-EOF
PredictionIO is an open source machine learning server for developers and data
scientists to create predictive engines for production environments. This gem
provides convenient access to the PredictionIO API for Ruby programmers so that
you can focus on application logic.
EOF
  s.version = PredictionIO::VERSION
  s.licenses = ['Apache-2.0']
  s.author = 'The PredictionIO Team'
  s.email = 'support@prediction.io'
  s.homepage = 'http://prediction.io/'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.0'
  s.files = Dir[File.join('lib', '**', '**')]
  s.add_runtime_dependency 'json', '>= 1.8'
end
