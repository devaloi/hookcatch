module Handlers
  module Github
    class PullRequestHandler < BaseHandler
      def call(delivery)
        payload = delivery.payload
        action = payload["action"]
        pr = payload["pull_request"] || {}
        number = pr["number"]
        title = pr["title"]

        Rails.logger.info(
          "[GitHub::PullRequest] ##{number} #{action}: #{title}"
        )
      end
    end
  end
end
