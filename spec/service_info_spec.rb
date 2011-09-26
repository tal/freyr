require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Freyr::ServiceInfo do
  subject {Freyr::ServiceInfo.new(:foo)}
  it "should set basic functions" do
    subject.restart_sig "START"
    subject.restart_sig.should == "START"
  end

  describe "logging" do

    it "should function like anything else" do
      subject.log "START"
      subject.log.should == "START"
      subject.dont_write_log.should_not == true
    end

    it "should return a default otherwise" do
      subject.log.should == Freyr::ServiceInfo::USER_LOGS+'/foo.log'
      subject.dont_write_log.should_not == true
    end

    it "should return root default" do
      subject.use_sudo
      subject.log.should == Freyr::ServiceInfo::ROOT_LOGS+'/foo.log'
      subject.dont_write_log.should_not == true
    end

    it "should go for read log" do
      subject.read_log "foo"
      subject.log.should == 'foo'
      subject.dont_write_log.should == true
    end

  end


  describe "pid_files" do
    
    it "should function like anything else" do
      subject.pid_file "START"
      subject.pid_file.should == "START"
    end

    it "should return a default otherwise" do
      subject.pid_file.should == Freyr::ServiceInfo::USER_PIDS+'/foo.pid'
    end

    it "should return root default" do
      subject.use_sudo
      subject.pid_file.should == Freyr::ServiceInfo::ROOT_PIDS+'/foo.pid'
    end

  end
end
