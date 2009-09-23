require 'open-uri'
require 'hpricot'

# lame!
OpenSSL::SSL.module_eval { remove_const :VERIFY_PEER }
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class Hoptoad < CampfireBot::Plugin
  at_interval 2.minutes, :report_deployments
  on_command 'apps', :deployments

  def initialize
    @url = "https://#{bot.config['hoptoad']['domain']}/projects?auth_token=#{bot.config['hoptoad']['auth_token']}"
  end

  def report_deployments(msg)
    parse_projects

    @project_times ||= {}
    projects.each do |project|
      name,time = project[:name], project[:latest_deploy]
      last_time = @project_times[name]

      if last_time && last_time != time
        msg.speak "#{name} was deployed at #{last_time}"
      end

      @project_times[name] = time
    end
  end

  def deployments(msg)
    projects.each do |p|
      msg.speak "#{p[:name]} [errors #{p[:resolved]}/#{p[:unresolved]}] #{p[:latest_deploy] ? "last deployed #{p[:latest_deploy]}" : 'never deployed'}"
    end
  end

  def projects
    parse_projects unless @projects
    @projects
  end

  def parse_projects
    @projects = doc.search('table.groups tbody tr').collect do |tr|
      tds = tr.search('td')
      {
        :name        => tds[0].inner_text,
        :errors      => tds[1].inner_text.to_i,
        :unresolved  => tds[2].inner_text.to_i,
        :resolved    => tds[3].inner_text.to_i,
        :latest_deploy => parse_deploy(tds[4].at('.timestamp'))
      }
    end
  end

  def parse_deploy(timestamp)
    return nil unless timestamp
    DateTime.strptime(timestamp['title'], "%d %b, %Y %H:%M %p")
  end

  def doc
    Hpricot(fetch_projects)
  end

  def fetch_projects
    open(@url)
  end
end
