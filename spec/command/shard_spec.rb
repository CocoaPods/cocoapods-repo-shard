require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Shard do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w( shard )).should.be.instance_of Command::Shard
      end
    end
  end
end
