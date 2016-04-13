require 'spec_helper'

describe Pod::Command::Repo::Shard do
  describe 'CLAide' do
    it 'registers itself' do
      expect(Pod::Command.parse(%w(repo shard))).to be_instance_of described_class
    end
  end

  describe '#validate!' do
    let(:argv) { %w() }
    subject { Pod::Command.parse(%w(repo shard) + argv) }

    context 'without arguments' do
      it 'raises due to missing repo name' do
        expect { subject.validate! }.to raise_error(CLAide::Help, /A repo name is required/)
      end
    end

    context 'with an unknown repo name' do
      let(:argv) { %w(missing-repo) }
      it 'raises due to missing repo name' do
        expect { subject.validate! }.to raise_error(CLAide::Help, /No repo named `missing-repo` found/)
      end
    end
  end

  describe 'sharding' do
    let(:repos_dir) { Pathname(Dir.mktmpdir) }
    let(:repo) { 'test_repo' }
    before do
      repos_dir.rmtree
      FileUtils.cp_r(Pod::Config.instance.repos_dir, repos_dir)
      Pod::Config.instance.repos_dir = repos_dir
      Dir.chdir(repos_dir + repo) do
        `git init .`
        `git add .`
        `git commit -am 'Initial Commit'`
      end
    end
    after do
      repos_dir # .rmtree
    end

    let(:argv) { [repo] }

    subject do
      described_class.invoke(argv)
      Pod::Config.instance.sources_manager.sources([repo]).first
    end

    context 'with explicit lengths' do
      let(:argv) { super() + %w(--lengths=1,2,3) }

      it 'shards correctly' do
        expect(subject.metadata.prefix_lengths).to eq([1, 2, 3])

        expect(subject.all_specs.map { |s| [s.to_s, s.defined_in_file] }.sort).to eq [
          ['BananaLib (0.0.1)', subject.specs_dir + '3/8e/ca9/BananaLib/0.0.1/BananaLib.podspec'],
          ['BananaLib (0.9)', subject.specs_dir + '3/8e/ca9/BananaLib/0.9/BananaLib.podspec'],
          ['BananaLib (1.0)', subject.specs_dir + '3/8e/ca9/BananaLib/1.0/BananaLib.podspec'],
          ['IncorrectPath (0.9)', subject.specs_dir + '9/0c/8c9/IncorrectPath/1.0/IncorrectPath.podspec'],
          ['JSONKit (1.13)', subject.specs_dir + '1/3f/e43/JSONKit/1.13/JSONKit.podspec'],
          ['JSONKit (1.4)', subject.specs_dir + '1/3f/e43/JSONKit/1.4/JSONKit.podspec'],
          ['JSONKit (999.999.999)', subject.specs_dir + '1/3f/e43/JSONKit/999.999.999/JSONKit.podspec'],
          ['JSONSpec (0.9)', subject.specs_dir + 'd/8d/54f/JSONSpec/0.9/JSONSpec.podspec.json'],
          ['JSONSpec (1.0)', subject.specs_dir + 'd/8d/54f/JSONSpec/1.0/JSONSpec.podspec.json'],
        ]
      end
    end

    context 'with implicit lengths' do
      it 'shards correctly' do
        expect(subject.metadata.prefix_lengths).to eq([])

        expect(subject.all_specs.map { |s| [s.to_s, s.defined_in_file] }.sort).to eq [
          ['BananaLib (0.0.1)', subject.specs_dir + 'BananaLib/0.0.1/BananaLib.podspec'],
          ['BananaLib (0.9)', subject.specs_dir + 'BananaLib/0.9/BananaLib.podspec'],
          ['BananaLib (1.0)', subject.specs_dir + 'BananaLib/1.0/BananaLib.podspec'],
          ['IncorrectPath (0.9)', subject.specs_dir + 'IncorrectPath/1.0/IncorrectPath.podspec'],
          ['JSONKit (1.13)', subject.specs_dir + 'JSONKit/1.13/JSONKit.podspec'],
          ['JSONKit (1.4)', subject.specs_dir + 'JSONKit/1.4/JSONKit.podspec'],
          ['JSONKit (999.999.999)', subject.specs_dir + 'JSONKit/999.999.999/JSONKit.podspec'],
          ['JSONSpec (0.9)', subject.specs_dir + 'JSONSpec/0.9/JSONSpec.podspec.json'],
          ['JSONSpec (1.0)', subject.specs_dir + 'JSONSpec/1.0/JSONSpec.podspec.json'],
        ]
      end
    end

    context 'with an already sharded directory' do
      before do
        described_class.invoke(%W(#{repo} --lengths=1,1))
      end

      context 're-sharding' do
        let(:argv) { super() + %w(--lengths=1,2,3) }

        it 'shards correctly' do
          expect(subject.metadata.prefix_lengths).to eq([1, 2, 3])

          expect(subject.all_specs.map { |s| [s.to_s, s.defined_in_file] }.sort).to eq [
            ['BananaLib (0.0.1)', subject.specs_dir + '3/8e/ca9/BananaLib/0.0.1/BananaLib.podspec'],
            ['BananaLib (0.9)', subject.specs_dir + '3/8e/ca9/BananaLib/0.9/BananaLib.podspec'],
            ['BananaLib (1.0)', subject.specs_dir + '3/8e/ca9/BananaLib/1.0/BananaLib.podspec'],
            ['IncorrectPath (0.9)', subject.specs_dir + '9/0c/8c9/IncorrectPath/1.0/IncorrectPath.podspec'],
            ['JSONKit (1.13)', subject.specs_dir + '1/3f/e43/JSONKit/1.13/JSONKit.podspec'],
            ['JSONKit (1.4)', subject.specs_dir + '1/3f/e43/JSONKit/1.4/JSONKit.podspec'],
            ['JSONKit (999.999.999)', subject.specs_dir + '1/3f/e43/JSONKit/999.999.999/JSONKit.podspec'],
            ['JSONSpec (0.9)', subject.specs_dir + 'd/8d/54f/JSONSpec/0.9/JSONSpec.podspec.json'],
            ['JSONSpec (1.0)', subject.specs_dir + 'd/8d/54f/JSONSpec/1.0/JSONSpec.podspec.json'],
          ]
        end
      end

      context 'un-sharding' do
        let(:argv) { super() + %w(--lengths=) }

        it 'shards correctly' do
          expect(subject.metadata.prefix_lengths).to eq([])

          expect(subject.all_specs.map { |s| [s.to_s, s.defined_in_file] }.sort).to eq [
            ['BananaLib (0.0.1)', subject.specs_dir + 'BananaLib/0.0.1/BananaLib.podspec'],
            ['BananaLib (0.9)', subject.specs_dir + 'BananaLib/0.9/BananaLib.podspec'],
            ['BananaLib (1.0)', subject.specs_dir + 'BananaLib/1.0/BananaLib.podspec'],
            ['IncorrectPath (0.9)', subject.specs_dir + 'IncorrectPath/1.0/IncorrectPath.podspec'],
            ['JSONKit (1.13)', subject.specs_dir + 'JSONKit/1.13/JSONKit.podspec'],
            ['JSONKit (1.4)', subject.specs_dir + 'JSONKit/1.4/JSONKit.podspec'],
            ['JSONKit (999.999.999)', subject.specs_dir + 'JSONKit/999.999.999/JSONKit.podspec'],
            ['JSONSpec (0.9)', subject.specs_dir + 'JSONSpec/0.9/JSONSpec.podspec.json'],
            ['JSONSpec (1.0)', subject.specs_dir + 'JSONSpec/1.0/JSONSpec.podspec.json'],
          ]
        end
      end
    end
  end
end
