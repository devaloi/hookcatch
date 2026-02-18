module Handlers
  module Github
    class PushHandler < BaseHandler
      def call(delivery)
        payload = delivery.payload
        repo = payload.dig("repository", "full_name")
        branch = payload["ref"]&.sub("refs/heads/", "")
        commits = payload["commits"]&.size || 0

        Rails.logger.info(
          "[GitHub::Push] #{repo} — #{branch}: #{commits} commit(s)"
        )
      end
    end
  end
end
