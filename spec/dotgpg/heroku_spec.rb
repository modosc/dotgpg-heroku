require 'spec_helper'

# why doesn't this autoload with factory girl?
require_relative '../factories/env_sync'

describe Dotgpg::Heroku do
  it 'has a version number' do
    expect(Dotgpg::Heroku::VERSION).not_to be nil
  end

  before(:each) do
    allow($stdout).to receive(:puts)
  end

  [:env_sync, :env_sync_added, :env_sync_changed, :env_sync_added_changed,
   :env_sync_added_removed, :env_sync_added_changed_removed,
   :env_sync_changed_removed,  :env_sync_removed, ].each do |k|
    let(k) { FactoryGirl.build k }
  end

  # setup a stub to catch our PUT request to heroku
  def stub_put_config_vars_for(vals)
    @stub = stub_request(:put, "https://api.heroku.com/apps/test-app/config_vars")
             .with(:body => JSON[vals])
             .to_return(:status => 200, :body => "", :headers => {})
  end

  describe "#removed" do
    it "works when keys match up" do
      expect(env_sync.removed).to be_empty
    end

    it "works when keys are removed" do
      expect(env_sync_removed.removed).to eq(['B'])
    end

    it "works when keys are added" do
      expect(env_sync_added.removed).to be_empty
    end
  end

  describe "#added" do
    it "works when keys match up" do
      expect(env_sync.added).to be_empty
    end

    it "works when keys are removed" do
      expect(env_sync_removed.added).to be_empty
    end

    it "works when keys are added" do
      expect(env_sync_added.added).to eq(['C'])
    end
  end

  describe "#changed" do
    it "works when keys match up" do
      expect(env_sync.changed).to be_empty
    end

    it "works when keys have different values" do
      expect(env_sync_changed.changed).to eq(['A', 'B'])
    end

    it "works when keys are removed" do
      expect(env_sync_removed.changed).to be_empty
    end

    it "works when keys are added" do
      expect(env_sync_added.changed).to be_empty
    end
  end

  describe "#sync" do
    describe "when keys have been removed" do
      it "raises and error and prints removed keys to $stdout" do
        env_sync_removed.removed.each do |c|
          expect{env_sync_removed.push}
            .to raise_error(Dotgpg::Heroku::RemoveError)
            .and output(/^#{c}$/).to_stdout
        end
      end
    end

    # in the next three describe blocks the logic is a bit wonky - ideally we'd
    # dynamically assemble an output expectation at runtime but i can't figure out
    # how to do that with rspec. instead we call :sync multiple times and check
    # for a different value in the output each time. this means we also have to
    # dynamically define our :have_been_requested expectation based on how many
    # times we looped. confusing and annoying, sorry!
    describe "when keys have been added" do
      before(:each) do
        stub_put_config_vars_for 'C' => 3
      end

      it "works" do
        expect(env_sync_added.push).to be_truthy
        expect(@stub).to have_been_requested
      end

      it "prints added keys to $stdout" do
        env_sync_added.added.each do |c|
          expect{env_sync_added.push}.to output(/^#{c}$/).to_stdout
        end
        expect(@stub).to have_been_requested.times(env_sync_added.added.length)
      end
    end

    describe "when keys have been changed" do
      before(:each) do
        stub_put_config_vars_for 'A' => 4, 'B' => 5
      end

      it "works" do
        expect(env_sync_changed.push).to be_truthy
        expect(@stub).to have_been_requested
      end
      it "prints changed keys to $stdout" do
        env_sync_changed.changed.each do |c|
          expect{env_sync_changed.push}.to output(/^#{c}$/).to_stdout
        end
        expect(@stub).to have_been_requested
          .times(env_sync_changed.changed.length)
      end
    end

    describe "when keys have been added and changed" do
      before(:each) do
        stub_put_config_vars_for 'A' => 4, 'B' => 5, 'C' => 3
      end

      it "works" do
        expect(env_sync_added_changed.push).to be_truthy
        expect(@stub).to have_been_requested
      end

      it "prints added and changed keys to $stdout" do
        (env_sync_added_changed.changed + env_sync_added_changed.added).each do |c|
          expect{env_sync_added_changed.push}.to output(/^#{c}$/).to_stdout
        end
        expect(@stub).to have_been_requested
          .times((env_sync_added_changed.changed + env_sync_added_changed.added).length)
      end
    end

    describe "when keys have been added and removed" do
      it "raises an error and prints removed keys to $stdout" do
        env_sync_added_removed.removed.each do |c|
          expect{env_sync_added_removed.push}
            .to raise_error(Dotgpg::Heroku::RemoveError)
            .and output(/^#{c}$/).to_stdout
        end
      end
    end

    describe "when keys have been added, changed, and removed" do
      it "raises an error and prints removed keys to $stdout" do
        env_sync_added_changed_removed.removed.each do |c|
          expect{env_sync_added_changed_removed.push}
            .to raise_error(Dotgpg::Heroku::RemoveError)
            .and output(/^#{c}$/).to_stdout
        end
      end
    end
  end
end
