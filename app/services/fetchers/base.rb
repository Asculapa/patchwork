module Fetchers
  class Base
    attr_reader :source

    def initialize(source)
      @source = source
    end

    # Returns a Fetchers::Result; raises Fetchers::Error when the source can't be fetched.
    def fetch
      raise NotImplementedError
    end
  end
end
