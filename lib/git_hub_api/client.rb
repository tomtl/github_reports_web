require 'faraday'
require 'json'
require 'logger'
require_relative 'middleware/logging'
require_relative 'middleware/authentication'
require_relative 'middleware/status_check'
require_relative 'middleware/json_parsing'
require_relative 'middleware/cache'
require_relative 'storage/redis'

module GitHubAPI

  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end
  class AuthenticationFailure < Error; end
  class ConfigurationError < Error; end
  class GistCreationFailure < Error; end
  class NonexistentRepo < Error; end
  class NonexistentGist < Error; end

  User = Struct.new(:name, :location, :public_repos)
  Event = Struct.new(:type, :repo_name)
  Repo = Struct.new(:name, :languages)
  Gist = Struct.new(:id, :url, :description, :files, :public, :created_at)
  GistFile = Struct.new(:name, :language, :content)
  Page = Struct.new(:page, :total_pages, :items)

  class Client

    def initialize(token)
      @token = token
    end

    def user_info(username)
      url = "https://api.github.com/users/#{username}"

      response = connection.get(url)

      data = response.body

      if response.status == 200
        # puts "\nRate limit remaining: #{response.headers['X-RateLimit-Remaining']}\n\r"
        User.new(data["name"], data["location"], data["public_repos"])
      else
        raise NonexistentUser, "'#{username}' does not exist"
      end
    end

    def public_repos_for_user(username, include_forks: true)
      url = "https://api.github.com/users/#{username}/repos"

      response = connection.get(url)
      raise NonexistentUser, "'#{username}' does not exist" unless response.status == 200

      repos = response.body

      link_header = response.headers['link']

      if link_header
        while match_data = link_header.match(/<(.*)>; rel="next"/)
          next_page_url = match_data[1]
          response = connection.get(next_page_url)
          link_header = response.headers['link']
          repos += response.body
        end
      end

      repos.map do |repo_data|
        next if !include_forks && repo_data["fork"]

        full_name = repo_data["full_name"]
        language_url = "https://api.github.com/repos/#{full_name}/languages"
        response = connection.get(language_url)
        Repo.new(repo_data["full_name"], response.body)
      end.compact
    end

    def public_events_for_user(username)
      url = "https://api.github.com/users/#{username}/events/public"

      response = connection.get(url)
      raise NonexistentUser, "'#{username}' does not exist" unless response.status == 200

      events = response.body

      link_header = response.headers['link']

      if link_header
        while match_data = link_header.match(/<(.*)>; rel="next"/)
          next_page_url = match_data[1]
          response = connection.get(next_page_url)
          link_header = response.headers['link']
          events += response.body
        end
      end

      events.map { |event_data| Event.new(event_data["type"], event_data["repo"]["name"]) }
    end

    def create_private_gist(description, filename, contents)
      url = "https://api.github.com/gists"
      payload = JSON.dump({
        description: description,
        public: false,
        files: {
          filename => {
            content: contents
          }
        }
      })

      response = connection.post url, payload

      if response.status == 201
        body = response.body
        Gist.new(
          body["id"],
          body["html_url"],
          body["description"],
          [],
          body["public"],
          body["created_at"]
        )
      else
        raise GistCreationFailure, response.body["message"]
      end
    end

    def gists(page:1)
      page = page.present? ? page.to_i : 1
      url = "https://api.github.com/gists"
      response = connection.get url

      last_page_url = header_link(response.headers, "last")

      if last_page_url
        uri = URI.parse(last_page_url)
        total_pages = Rack::Utils.parse_query(uri.query)["page"].to_i
      else
        total_pages = page
      end

      items = response.body.map do |gist_data|
        Gist.new(
          gist_data["id"],
          gist_data["html_url"],
          gist_data["description"],
          [],
          gist_data["public"],
          gist_data["created_at"]
        )
      end

      Page.new(page, total_pages, items)
    end

    def gist_info(gist_id)
      url = "https://api.github.com/gists/#{gist_id}"

      response = connection.get(url)

      if response.status == 200
        gist = response.body
        files = gist["files"].map do |(name, file)|
          GistFile.new(name, file["language"], file["content"])
        end
        Gist.new(gist["id"],
                 gist["html_url"],
                 gist["description"],
                 files, gist["public"],
                 gist["created_at"])
      else
        raise NonexistentGist, "No gist found with id #{gist_id}."
      end
    end

    def delete_gist(gist_id)
      url = "https://api.github.com/gists/#{gist_id}"

      response = connection.delete(url)

      if response.status != 204
        raise NonexistentGist, "No gist found with id #{gist_id}."
      end
    end

    def header_link(headers, link_name)
      header = headers["link"]

      if header
        links = header.split(",").inject({}) do |sum, link|
          url_part, rel_part = link.split(";")
          url = url_part.tr("<>", "").strip
          name = rel_part.match(/rel="(.*)"/)[1].strip
          sum[name] = url
          sum
        end
      else
        links = {}
      end

      links[link_name]
    end

    def repo_starred?(full_repo_name)
      url = "https://api.github.com/user/starred/#{full_repo_name}"
      response = connection.get url
      response.status == 204
    end

    def star_repo(full_repo_name)
      url = "https://api.github.com/user/starred/#{full_repo_name}"
      response = connection.put url
      raise RequestFailure, response.body['message'] unless response.status == 204
    end

    def unstar_repo(full_repo_name)
      url = "https://api.github.com/user/starred/#{full_repo_name}"
      response = connection.delete url
      raise RequestFailure, response.body['message'] unless response.status == 204
    end

    def connection
      @connection ||= Faraday::Connection.new do |builder|
        builder.use Middleware::StatusCheck
        builder.use Middleware::Authentication, @token
        builder.use Middleware::JSONParsing
        builder.use Middleware::Logging, Rails.logger
        builder.use Middleware::Cache, Rails.cache
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
