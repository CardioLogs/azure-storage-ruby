# frozen_string_literal: true

#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------

module Azure::Storage::Common::Core
  module HttpClient
    # Caching HTTP connections by domain
    def agents(uri)
      @agents ||= {}
      domain = uri.to_s[%r{([^\/]*\/){4}}]
      @agents[domain] = build_http(uri) unless @agents.key?(domain)
      @agents[domain]
    end

    # Empties all the http agents
    def reset_agents!
      @agents = nil
    end

    private

      # Empties all information that cannot be reused.
      def reuse_agent!(agent)
        agent.params.clear
        agent.headers.clear
      end

      def build_http(uri)
        ssl_options = {}
        if uri.is_a?(URI) && uri.scheme.downcase == "https"
          ssl_options[:version] = self.ssl_version if self.ssl_version
          # min_version and max_version only supported in ruby 2.5
          ssl_options[:min_version] = self.ssl_min_version if self.ssl_min_version
          ssl_options[:max_version] = self.ssl_max_version if self.ssl_max_version
          ssl_options[:ca_file] = self.ca_file if self.ca_file
          ssl_options[:verify] = true
        end
        proxy_options = if ENV["HTTP_PROXY"]
                          URI::parse(ENV["HTTP_PROXY"])
                        elsif ENV["HTTPS_PROXY"]
                          URI::parse(ENV["HTTPS_PROXY"])
                        end || nil
        Faraday.new(uri, ssl: ssl_options, proxy: proxy_options) do |conn|
          conn.use FaradayMiddleware::FollowRedirects
          conn.adapter Faraday.default_adapter
        end
      end
  end
end
