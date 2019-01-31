require 'net/http'
require 'json'

require_relative 'team_strength.rb'
require_relative 'constants.rb'
require_relative 'team_compare.rb'

class Season
	def initialize
		@remaining_schedule = get_remaining_schedule
		@standings = get_standings
	end
	
	def test
		sc = @standings
		add_points(20, sc)
		puts sc
	end
	
	def get_standings
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/standings")
		json_response = JSON.parse(response)
		div_standings = Hash.new
		@strengths = Hash.new
		@names = Hash.new
		json_response["records"].each do |division|
			div_standings[division["division"]["name"]] = Hash.new
			division["teamRecords"].each do |team|
				div_standings[division["division"]["name"]][team["team"]["id"]] = team["points"]
				@strengths[team["team"]["id"]] = Team_Strength.new(team["team"]["id"])
				@names[team["team"]["id"]] = team["team"]["name"]
			end
		end
		return div_standings
	end
	
	def get_remaining_schedule
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?startDate=#{Time.now.strftime("%Y-%m-%d")}&endDate=#{SEASON_END_DATE}")
		json_response = JSON.parse(response)
		return json_response["dates"]
	end
	
	def add_points(win_id, standings)
		standings.each do |div|
			if div[1].key?(win_id)
				div[1][win_id] += 2
			end
		end
	end
	
	def determine_playoff_spots(div1, div2)
		playoff_teams = Array.new
		sorted1 = div1.sort_by { |k,v| -v } 
		sorted2 = div2.sort_by { |k,v| -v }
		#TODO: for top 5 in each division fix any ties
		#TODO: find pres trophy winner in here
		for i in 0..2
			playoff_teams.push(sorted1[i][0])
			playoff_teams.push(sorted2[i][0])
		end
		#spots 3 and four in arrays are potential wildcard candidates, will need special cases if the are equal
		#admittedly somewhat confusing
		if sorted1[3][1] > sorted2[3][1]
			playoff_teams.push(sorted1[3][0])
			if sorted1[4][1] > sorted2[3][1]
				playoff_teams.push(sorted1[4][0])
			else
				playoff_teams.push(sorted2[3][0])
			end
		else
			playoff_teams.push(sorted2[3][0])
			if sorted2[4][1] > sorted1[3][1]
				playoff_teams.push(sorted2[4][0])
			else
				playoff_teams.push(sorted1[3][0])
			end
		end
		return playoff_teams
	end
	
	
	def simulate_season
		randomizer = Random.new
		standings_copy = @standings # to prevent multi access issues
		@remaining_schedule.each do |day|
			next if day["date"] == ASG_DATE
			day["games"].each do |game|
				#puts "home id: #{game["teams"]["home"]["team"]["id"]} | away id: #{game["teams"]["home"]["team"]["id"]}"
				result = Team_Compare.new(@strengths[game["teams"]["home"]["team"]["id"]], @strengths[game["teams"]["away"]["team"]["id"]], true)
				odds = result.compare
				game_result = randomizer.rand
				if odds > game_result
					add_points(game["teams"]["home"]["team"]["id"], standings_copy)
				else
					add_points(game["teams"]["away"]["team"]["id"], standings_copy)
				end
			end
		end
		east_playoffs = determine_playoff_spots(standings_copy["Metropolitan"], standings_copy["Atlantic"])
		west_playoffs = determine_playoff_spots(standings_copy["Central"], standings_copy["Pacific"])

		return {:west => west_playoffs, :east => east_playoffs}
	end

	def simulate_season_controller(n)
		threads = Array.new(n)
		i = 0
		while i < n
			threads[i] = Thread.new{simulate_season}
			i += 1
		end
		east_playoffs = Hash.new
		west_playoffs = Hash.new
		pres_trophy = Hash.new
		threads.each do |t|
			playoff_teams = t.value
			playoff_teams[:east].each do |id|
				if east_playoffs.key?(id)
					east_playoffs[id] += 1
				else
					east_playoffs[id] = 1
				end
			end
			#repetition
			playoff_teams[:west].each do |id|
				if west_playoffs.key?(id)
					west_playoffs[id] += 1
				else
					west_playoffs[id] = 1
				end
			end
		end
		
		puts "Eastern Conference"
		east_playoffs.each do |id, count|
			puts "#{@names[id]} have a #{((count.to_f / n) * 100).round(2)}% chance of making the playoffs"
		end
		puts "Western Conference"
		west_playoffs.each do |id, count|
			puts "#{@names[id]} have a #{((count.to_f / n) * 100).round(2)}% chance of making the playoffs"
		end
	end
end


#test driver

s = Season.new
#s.test
s.simulate_season_controller(1)