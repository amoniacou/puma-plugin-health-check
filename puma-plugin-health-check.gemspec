# frozen_string_literal: true

require_relative 'lib/puma_plugin_health_check/version'

Gem::Specification.new do |spec|
  spec.name          = 'puma-plugin-health-check'
  spec.version       = PumaPluginHealthCheck::VERSION
  spec.authors       = ['Oleksandr Simonov']
  spec.email         = ['oleksandr@amoniac.eu']
  spec.summary       = 'Puma plugin for Kubernetes-style health check endpoints'
  spec.description   = 'Lightweight Puma plugin that exposes liveness and readiness ' \
                       'health check endpoints on a separate TCP port.'
  spec.homepage      = 'https://github.com/amoniacou/puma-plugin-health-check'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.files = Dir['lib/**/*', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'puma', '>= 6.0'

  spec.add_development_dependency 'appraisal', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
