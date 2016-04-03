require 'bundler/setup'
require 'cocoapods'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require File.expand_path('../../lib/cocoapods_plugin', __FILE__)

#-----------------------------------------------------------------------------#

module Pod
  # Disable the wrapping so the output is deterministic in the tests.
  #
  UI.disable_wrap = true

  # Redirects the messages to an internal store.
  #
  module UI
    @output = ''
    @warnings = ''

    class << self
      attr_accessor :output
      attr_accessor :warnings

      def puts(message = '')
        @output << "#{message}\n"
      end

      def warn(message = '', _actions = [])
        @warnings << "#{message}\n"
      end

      def print(message)
        @output << message
      end
    end
  end
end

#-----------------------------------------------------------------------------#

RSpec.configure do |c|
  c.before(:each) do
    Pod::UI.output = ''
    Pod::UI.warnings = ''

    Pod::Config.instance.repos_dir = Pathname(__FILE__) + '../fixtures/spec-repos'
    Pod::Config.instance.verbose = false
  end
end
