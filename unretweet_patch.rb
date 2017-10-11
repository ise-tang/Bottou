module Twitter
  module REST
    module Tweets
      # Untweets a retweeted status as the authenticating user
      #
      # @see https://dev.twitter.com/rest/reference/post/statuses/unretweet/:id
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @return [Array<Twitter::Tweet>] The original tweets with retweet details embedded.
      # @overload unretweet(*tweets)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      # @overload unretweet(*tweets, options)
      #   @param tweets [Enumerable<Integer, String, URI, Twitter::Tweet>] A collection of Tweet IDs, URIs, or objects.
      #   @param options [Hash] A customizable set of options.
      #   @option options [Boolean, String, Integer] :trim_user Each tweet returned in a timeline will include a user object with only the author's numerical ID when set to true, 't' or 1.
      def unretweet(*args)
        arguments = Twitter::Arguments.new(args)
        pmap(arguments) do |tweet|
          begin
            post_unretweet(extract_id(tweet), arguments.options)
          rescue Twitter::Error::NotFound
            next
          end
        end.compact
      end

    private

      def post_unretweet(tweet, options)
        response = perform_post("/1.1/statuses/unretweet/#{extract_id(tweet)}.json", options)
        Twitter::Tweet.new(response)
      end
    end
  end
end