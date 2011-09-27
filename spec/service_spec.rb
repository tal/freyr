require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Freyr::Service do
  before :all do
    Freyr::OUT.reopen('/dev/null')
  end
  subject do
    si = Freyr::ServiceInfo.new(:foo) do
      start 'sleep 10'
      proc_match /sleep 10/
      ping 'http://google.com'
    end

    Freyr::Service.new(si)
  end

  describe 'starting' do
    it "should start" do
      subject.start!

      subject.pid_file.pid_from_procname.should_not be_nil
    end
  end
end
