# cocoapods-repo-shard

This plugin allows sharding a spec repo's `Specs` directory to be more performant under various `git` operations. By sharding a repository, a large amount of specs can be stored at logarithmic cost, rather than linear cost. Most private specs repos will never have to be concerned with the particular performance characteristics of git, but the [master specs repo](https://github.com/CocoaPods/Specs) is large enough that sharding will bring a massive performance gain.

## Installation

    $ gem install cocoapods-repo-shard

## Usage

    $ pod repo shard REPO_NAME --lengths=1,1,1
