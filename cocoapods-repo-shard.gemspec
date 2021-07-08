# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_repo_shard/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-repo-shard'
  spec.version       = CocoapodsRepoShard::VERSION
  spec.authors       = ['Samuel Giddins']
  spec.email         = ['segiddins@segiddins.me']
  spec.summary       = 'Shard a CocoaPods specs repository.'
  spec.homepage      = 'https://github.com/CocoaPods/cocoapods-repo-shard'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake',    '~> 13.0'
end
