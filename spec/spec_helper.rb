require 'spec'
require 'pathname'
require 'pp'

__DIR__ = Pathname(__FILE__).dirname

BOT_ROOT = __DIR__.join('..').expand_path.to_s
BOT_ENVIRONMENT = 'test'


$:.unshift __DIR__.join('..','lib').expand_path.to_s
$:.unshift __DIR__.join('..','plugins').expand_path.to_s

require 'bot'

module FixtureHelper
  def fixture(*name)
    Pathname(__FILE__).dirname.join('fixtures',*name).read
  end
end

module PluginHelper
  def plugin(klass, config={})
    bot = CampfireBot::Bot.instance
    bot.stub!(:config).and_return({'nickname' => 'Bot'}.merge(config))

    plugin = klass.new
    CampfireBot::Plugin.registered_plugins[klass.to_s] = plugin
    plugin
  end

end

Spec::Runner.configure do |config|
  config.include FixtureHelper
  config.include PluginHelper
end
