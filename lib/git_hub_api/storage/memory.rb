module GitHubAPI
  module Storage
    class Memory
      def initialize(hash = {})
        @hash = hash
      end

      def read(key)
        @hash[key]
      end

      def write(key, value)
        @hash[key]= value
      end
    end
  end
end
