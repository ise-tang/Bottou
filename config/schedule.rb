# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 3.minutes do
  command 'cd /home/issei/Bottou && bundle exec ruby markov_tweet.rb >> /home/issei/Bottou/log/markov_log'
  command 'cd /home/issei/Bottou && bundle exec ruby Bottou_reply.rb >> /home/issei/Bottou/log/reply_log'
end