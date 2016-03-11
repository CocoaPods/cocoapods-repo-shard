module Pod
  class Command
    class Repo
      # This is an example of a cocoapods plugin adding a top-level subcommand
      # to the 'pod' command.
      #
      # You can also create subcommands of existing or new commands. Say you
      # wanted to add a subcommand to `list` to show newly deprecated pods,
      # (e.g. `pod list deprecated`), there are a few things that would need
      # to change.
      #
      # - move this file to `lib/pod/command/list/deprecated.rb` and update
      #   the class to exist in the the Pod::Command::List namespace
      # - change this class to extend from `List` instead of `Command`. This
      #   tells the plugin system that it is a subcommand of `list`.
      # - edit `lib/cocoapods_plugins.rb` to require this file
      #
      # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
      #       in the `plugins.json` file, once your plugin is released.
      #
      class Shard < Repo
        self.summary = 'Short description of cocoapods-repo-shard.'

        self.description = <<-DESC
          Longer description of cocoapods-repo-shard.
        DESC

        self.arguments = [
          CLAide::Argument.new('NAME'),
        ]

        def self.options
          [
            ['--lengths=l1,l2,...', 'the lengths'],
          ].concat(super)
        end

        def initialize(argv)
          @name = argv.shift_argument
          @lengths = argv.flag('lengths')
          super
        end

        def validate!
          help! 'A repo name is required.' unless @name
          if @lengths
            @lengths = @lengths.split(',').map(&:to_i)
            help! 'all l must be +' if @lengths.any? { |l| l <= 0 }
          end
          super
        end

        def run
          require 'cocoapods'
          require 'digest/md5'
          require 'fileutils'
          require 'tmpdir'

          source = Pod::SourcesManager.master.first
          names = source.pods

          new_dir = Pathname('~/.cocoapods/repos/master-experimental').expand_path
          new_dir.rmtree

          specs = new_dir.join('Specs')
          specs.mkpath

          lengths = [1, 1, 1]

          hashes = names.map { |n| [n, Digest::MD5.hexdigest(n)] }
          paths = hashes.map do |name, hash|
            lengths.each_with_object([]) { |l, a| a << hash[a.map(&:size).reduce(0, &:+), l] } << name
          end

          paths.each do |components|
            name = components.pop
            path = specs.join(*components)
            path.mkpath
            FileUtils.cp_r(source.send(:specs_dir) + name, path + name)
          end

          Dir.chdir(new_dir) do
            `git init .`
            `git add .`
            `git commit -am 'Initial commit'`
          end
        end

        private

        def temp_specs_dir
          @temp_specs_dir ||= Pathname(Dir.mktmpdir)
        end

        def ideal_lengths(total)
          possibilities = (0..3).cycle.first(4 * 4).permutation(4).to_a.
            each(&:sort!).uniq.each { |perm| perm.delete(0) }
          possibilities.min_by do |perm|
            cost(total, perm) + 0.75 * cost(total * 2, perm)
          end
        end

        def cost(total, lengths)
          (total / (16**lengths.reduce(&:+))) +
            lengths.reduce(0) { |s, l| s + 16**l }
        end
      end
    end
  end
end
