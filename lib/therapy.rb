require 'git'
require 'net/http'

class Therapy
  attr_accessor :username, :repository, :config
  def initialize()
    @git = Git.open(Dir.pwd)
    @config = Git.global_config
    
    origin_url = @git.remote('origin').url
    origin_url =~ /git@github\.com:(.*)\/(.*)\.git/
    @username = $1
    @repository = $2

    @out = $stdout
  end


  def list
    fetch_issues unless File.exist?(open_issues_file)

    open_issues.each do |issue|
      @out.puts "##{issue['number'].to_s.ljust 3} #{issue['state'].rjust 6}: #{issue['title']}"
    end
  end

  def show(number)
    fetch_issue(number) unless File.exist?(issue_file(number))

    issue = YAML.load(File.read(issue_file(number)))['issue']

    @out.puts "##{issue['number']} #{issue['state']}: #{issue['title']}"
    @out.puts
    @out.puts "user   : #{issue['user']}"
    @out.puts "created: #{issue['created_at']}"
    @out.puts "updated: #{issue['updated_at']}"
    @out.puts "votes  : #{issue['votes']}"
    @out.puts
    @out.puts issue['body']
  end

  def fetch
    fetch_issues
  end

  def open_issues
    YAML.load(File.read(open_issues_file))['issues']
  end

  private

  def fetch_issues
    @out.puts "Fetching issues for #{@username}/#{@repository}"

    FileUtils.mkdir_p(issues_dir)

    response = Net::HTTP.post_form(URI.parse(list_issues_url), post_auth)    
    @out.puts "There was an error fetching the issues (#{response.code}): #{response.body}" and return if response.code != '200'

    File.open open_issues_file, "w" do |file|
      file.write response.body
    end

    open_issues.each do |issue|
      fetch_issue(issue['number'])
    end
  end

  def fetch_issue(number)
    @out.puts "Fetching issue #{number} for #{@username}/#{@repository}"

    FileUtils.mkdir_p(issues_dir)

    response = Net::HTTP.post_form(URI.parse(show_issues_url(number)), post_auth)
    @out.puts "There was an error fetching the issues (#{response.code}): #{response.body}" and return if response.code != '200'

    File.open issue_file(number), "w" do |file|
      file.write response.body
    end
  end

  def issues_dir
    '.git/issues'
  end

  def show_issues_url(number)
    "http://github.com/api/v2/yaml/issues/show/#{username}/#{repository}/#{number}"
  end

  def list_issues_url
    "http://github.com/api/v2/yaml/issues/list/#{username}/#{repository}/open"
  end

  def open_issues_file
    "#{issues_dir}/open.yml"
  end

  def issue_file(number)
    "#{issues_dir}/#{number}.yml"
  end

  def post_auth
    options = {}
    if (@config['github.token'] && @config['github.user'])
      options['token'] = @config['github.token']
      options['login'] = @config['github.user']
    end  
    options
  end
end
