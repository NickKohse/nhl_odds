require 'net/http'
require 'json'

require_relative 'constants.rb'

class Team_Strength
	def initialize(id)
		#store the values in a has, or just extract the already existing hash to reduce the number of attr_readers
		@team_id = id 
		@stats = get_team_stats(id)

		@record_factor = @stats["wins"].to_f / @stats["gamesPlayed"].to_f

		@ppg = @stats["powerPlayGoals"].to_f
		@ppga = @stats["powerPlayGoalsAgainst"].to_f

		@shots_for = @stats["shotsPerGame"].to_f #these to_f's might be unnecessary 
		@shots_against = @stats["shotsAllowed"].to_f
	end
	
	def get_team_stats(id)
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/teams/#{id}?expand=team.stats")
		json_response = JSON.parse(response)
		return json_response["teams"][0]["teamStats"][0]["splits"][0]["stat"]
	end
	
	attr_reader :record_factor
	attr_reader :ppg
	attr_reader :ppga
	attr_reader :shots_for
	attr_reader :shots_against
	attr_reader :team_id
end