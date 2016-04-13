module Pod
  class Command
    class Repo
      class Shard < Repo
        self.summary = 'Shards a CocoaPods specs repo in-place.'

        self.arguments = [
          CLAide::Argument.new('NAME', true),
        ]

        attr_reader :source
        attr_reader :name
        attr_reader :lengths

        def self.options
          [
            ['--lengths=l1,l2,...', 'The prefix lengths to shard the source with'],
          ].concat(super)
        end

        def initialize(argv)
          @name = argv.shift_argument
          @lengths = argv.option('lengths')
          super
        end

        def validate!
          help! 'A repo name is required.' unless @name

          @source = config.sources_manager.sources([@name]).first
          help! "No repo named `#{@name}` found." unless source.specs_dir
          unless source.specs_dir.basename.to_s == 'Specs'
            raise Informative, 'Cannot shard a repo that does not use the `Specs` directory'
          end

          if lengths
            @lengths = lengths.split(',').map(&:to_i)
            help! 'All lengths must be positive' if lengths.any? { |l| l <= 0 }
          end

          super
        end

        extend Executable
        executable :git

        def run
          require 'fileutils'
          require 'yaml'

          @lengths ||= ideal_lengths(source.pods.size).tap do |ideal_lengths|
            UI.puts "Sharding to ideal prefix lengths #{ideal_lengths.inspect}"
          end

          new_specs_dir = source.repo + 'temp_specs_dir'
          new_specs_dir.mkpath

          new_metadata = Source::Metadata.new(source.metadata.to_hash.update('prefix_lengths' => @lengths))

          UI.puts 'Copying specs into sharded structure'
          source.pods.each do |name|
            path = new_specs_dir.join(new_metadata.path_fragment(name))
            path.parent.mkpath
            FileUtils.cp_r(source.pod_path(name), path)
          end

          UI.puts 'Replacing existing specs directory with sharded copy'
          source.specs_dir.rmtree
          FileUtils.mv(new_specs_dir, source.specs_dir)

          UI.puts 'Writing updated source metadata'
          source.metadata_path.open('w') { |f| f.write(YAML.dump(new_metadata.to_hash)) }
          source.send(:refresh_metadata)

          UI.section 'Committing changes to the specs repo' do
            Dir.chdir(source.repo) do
              git! 'add', source.specs_dir
              git! 'add', source.metadata_path
              git! 'commit', '-m',
                   "Sharded to use #{lengths.inspect} prefix lengths"
            end
          end

          UI.puts "Finished sharding the #{source.name} repo.\n" \
                  "After verifying the changes, push the changes in #{UI.path(source.repo)} upstream."
        ensure
          new_specs_dir.rmtree if new_specs_dir && new_specs_dir.directory?
        end

        private

        def ideal_lengths(total)
          possibilities = (0..3).cycle.first(4 * 4).permutation(4).to_a.
                          each(&:sort!).uniq.each { |perm| perm.delete(0) }
          possibilities.min_by do |perm|
            cost(total, perm) +
              0.75 * cost(total * 2, perm) +
              0.33 * cost(total * 4, perm)
          end
        end

        def cost(total, lengths)
          (total / (16**lengths.reduce(0, &:+))) +
            lengths.reduce(0) { |s, l| s + 16**l }
        end
      end
    end
  end
end
