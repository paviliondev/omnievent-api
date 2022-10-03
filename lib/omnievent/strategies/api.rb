# frozen_string_literal: true

require_relative "../../omnievent/api/version"
require "excon"

module OmniEvent
  module Strategies
    # Generic strategy for listing events from an API
    class API
      class Error < StandardError; end
      class NotImplementedError < NotImplementedError; end

      include OmniEvent::Strategy

      def self.inherited(subclass)
        super
        OmniEvent::Strategy.included(subclass)
      end

      option :name, "api"
      option :token, ""

      REDIRECT_LIMIT = 5

      def raw_events
        raise NotImplementedError
      end

      def event_hash(raw_event)
        raise NotImplementedError
      end

      def authorized?
        !!options.token
      end

      def request_url
        raise NotImplementedError
      end

      def request_path
        raise NotImplementedError
      end

      def request_headers
        raise NotImplementedError
      end

      def perform_request(opts = {})
        request_opts = { path: request_path }.merge(opts)
        request_response = request_connection.get(request_opts)

        redirect = 0
        while redirect < REDIRECT_LIMIT && [301, 302, 303, 307, 308].include?(request_response.status)
          redirect += 1
          request_opts = request_opts.merge(url: request_response.headers["Location"])
          request_response = request_connection.get(request_opts)
        end

        request_error unless request_response.status == 200

        begin
          JSON.parse(request_response.body)
        rescue JSON::ParserError
          request_error
        end
      end

      def request_connection
        @request_connection ||= Excon.new(
          request_url,
          headers: request_headers
        )
      end

      def request_error
        message = "Failed to retrieve events from #{options.name}"
        log(:error, message)
        raise Error, message
      end
    end
  end
end
