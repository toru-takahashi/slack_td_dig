class SlackHistory
  require 'slack-ruby-client'
  require 'date'
  require 'td-logger'
  require 'json'

  def channels
    # TODO: Use Secret by rb operator
    token = File.read(File.expand_path('~/.config/digdag/secrets/slack_td.token'))
    client = Slack::Web::Client.new(token: token)
    
    channels = Array.new

    client.channels_list.channels.each do |c|
      if c['name'].start_with?(Digdag.env.params['channel_prefix'])
        puts "- name: #{c['name']}, id: #{c['id']}"
        channels << c
      end
    end

    Digdag.env.store(channels: channels)
  end

  def history
    # TODO: Use Secret by rb operator
    token = File.read(File.expand_path('~/.config/digdag/secrets/slack_td.token'))
    apikey = File.read(File.expand_path('~/.config/digdag/secrets/slack_td.td_apikey'))
    client = Slack::Web::Client.new(token: token)
    oldest = 0
    latest = Digdag.env.params['session_unixtime']

    TreasureData::Logger.open(Digdag.env.params['td_database'], :apikey => apikey, :auto_create_table => true)

    channel = JSON.parse(Digdag.env.params['channel'])

    loop do
      history = client.channels_history(
        channel: channel['id'],
        oldest: oldest,
        latest: latest,
        inclusive: true,
        count: 1000
      )
      
      break if history['messages'].length == 0
      
      puts "Sending #{history['messages'].length} records from #{channel['id']}-#{channel['name']} less than #{latest}..."
      
      history['messages'].each do |message|
        TD.event.post_with_time(Digdag.env.params['td_table'], record(channel, message), message['ts'].to_i)
      end
      latest = history['messages'].last['ts']
      break unless history['has_more']
    end
  end

  def record(channel, message)
    {
      channel_id: channel['id'],
      channel_name: channel['name'],
      message_type: message['type'],
      message_ts: message['ts'],
      message_user: message['user'],
      message_text: message['text'],
      message_is_starred: message['is_starred'],
      message_reactions: message['reactions'],
      message_wibblr: message['wibblr']
    }
  end

  def users
    token = File.read(File.expand_path('~/.config/digdag/secrets/slack_td.token'))
    apikey = File.read(File.expand_path('~/.config/digdag/secrets/slack_td.td_apikey'))
    client = Slack::Web::Client.new(token: token)

    TreasureData::Logger.open(Digdag.env.params['td_database'], :apikey => apikey, :auto_create_table => true)

    client.users_list.members.each do |member|
      TD.event.post(Digdag.env.params['td_table'], member)
    end
  end

end
