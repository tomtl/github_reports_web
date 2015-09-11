require 'dalli'

module GitHubAPI
  module Storage
    class Memcached

      def initialize(memcached=Dalli::Client.new)
        @memcached = memcached

        memcached.alive! # verify we can connect to the server
      rescue Dalli::RingError => e
        raise Reports::ConfigurationError.new("Could not connect to memcached: #{e.message}")
      end

      def read(key)
        value = @memcached.get(key)
        Marshal.load(value) if value
      end

      def write(key, value)
        @memcached.set(key, Marshal.dump(value))
      end
    end
  end
end
