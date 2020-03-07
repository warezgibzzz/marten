module Marten
  module Server
    def self.run
      server = ::HTTP::Server.new(
        [
          ::HTTP::ErrorHandler.new,
          Handlers::Routing.new,
        ]
      )
      server.bind_tcp("0.0.0.0", 8000)
      server.listen
    end
  end
end
