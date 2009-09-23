require File.dirname(__FILE__)+'/spec_helper'
require 'hoptoad'

gem 'fakeweb'
require 'fakeweb'

describe Hoptoad do
  before do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = true
  end

  it "is a Plugin" do
    Hoptoad.superclass.should == CampfireBot::Plugin
  end

  before do
    @ht = plugin(Hoptoad, 'hoptoad' => {'domain' => 'myhop.hoptoadapp.com', 'auth_token' => '0xdeadbeef'})
  end

  describe "#fetch_projects" do
    it "hits hoptoad" do
      FakeWeb.allow_net_connect = false
      FakeWeb.register_uri(:get, 'https://myhop.hoptoadapp.com/projects?auth_token=0xdeadbeef', :body => fixture('hoptoad','projects.html'))
      @ht.fetch_projects.should respond_to(:read)
    end
  end

  describe '(with faked html)' do
    before do
      @ht.stub!(:fetch_projects).and_return(fixture('hoptoad','projects.html'))
    end

    describe "#doc" do
      it "gets a doc" do
        @ht.doc.should be_instance_of(Hpricot::Doc)
      end
    end

    describe "#projects" do
      it "fetches projects" do
        @ht.parse_projects
        @ht.projects.should == [
          {:name => 'eggs.org.au', :errors => 9, :unresolved => 3, :resolved => 6, :latest_deploy => DateTime.parse('2009-08-25 05:52:00')},
          {:unresolved=>23, :resolved=>53, :name=>"Golfo", :latest_deploy=>DateTime.parse('Tue, 15 Sep 2009 06:25:00 +0000'), :errors=>76},
          {:unresolved=>0, :resolved=>0, :name=>"sonics", :latest_deploy=>nil, :errors=>0},
          {:unresolved=>2, :resolved=>4, :name=>"Swellnet", :latest_deploy=>DateTime.parse('Tue, 25 Aug 2009 07:47:00 +0000'), :errors=>6},
          {:unresolved=>3, :resolved=>31, :name=>"Weatherzone Facebook", :latest_deploy=>DateTime.parse('Thu, 17 Sep 2009 04:33:00 +0000'), :errors=>34},
          {:unresolved=>3, :resolved=>42, :name=>"wx", :latest_deploy=>DateTime.parse('Thu, 17 Sep 2009 05:09:00 +0000'), :errors=>45}
        ]
      end
    end
  end

  describe "#report_deployments" do
    before do
      @msg = CampfireBot::Message.new({})
      @projects = []
      @ht.should_receive(:projects).at_least(:once).and_return(@projects)
    end

    it "returns nothing first go" do
      @projects << {
        :name => 'foobar', :latest_deploy => Time.now
      }
      @msg.should_not_receive(:speak)
      @ht.report_deployments(@msg)
    end

    it "speaks a message on changes" do
      @projects << {
        :name => 'foobar', :latest_deploy => (Time.now-10.minutes)
      }
      @ht.report_deployments(@msg)


      @msg.should_receive(:speak).once.with(an_instance_of(String))
      @projects[0] = {
        :name => 'foobar', :latest_deploy => Time.now
      }
      @ht.report_deployments(@msg)
    end
  end

  describe "#apps" do
    before do
      @msg = CampfireBot::Message.new({})
      @projects = []
      @ht.should_receive(:projects).at_least(:once).and_return(@projects)
    end

    it "tells us about the apps" do
      @projects << {:name => 'mooper', :errors => 15, :resolved => 5, :unresolved => 10, :latest_deploy => Time.now}
      @projects << {:name => 'fooper', :errors => 15, :resolved => 5, :unresolved => 10, :latest_deploy => nil}
      @msg.should_receive(:speak).twice.with(an_instance_of(String))
      @ht.deployments(@msg)
    end
  end
end
