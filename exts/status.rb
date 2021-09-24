require "discorb"

module Core::Status
  extend Discorb::Extension

  %i[standby guild_join guild_leave].each do |event_name|
    event event_name do
      @client.update_presence(
        Discorb::Activity.new(
          name: "#{client.guilds.length} Servers"
        ),
        status: :online
      )
    end
  end
  
  event :ready do
    @client.update_presence(
      status: :dnd,
    )
  end
end