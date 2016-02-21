$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dotgpg/heroku'

# adapted/copied from dotgpg
# Make a totally isolated directory for running tests.
# This is necessary because GPG maintains state in GNUPGHOME,
# and we don't want running the tests to spoil developer's real key stores.
$fixtures = Pathname.new(Dir::mktmpdir).realpath
FileUtils.cp_r "spec/fixtures/", $fixtures
$fixtures += "fixtures"
$keys = $fixtures + "keys"
$dotgpg = $fixtures + "config/dotgpg"
ENV["GNUPGHOME"] = $fixtures.join("gnupghome").to_s
at_exit{ FileUtils.rm_rf $fixtures }

require 'heroku_san'
require 'factory_girl'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
require 'json'
