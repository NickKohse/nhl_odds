require 'net/http'
require 'json'

NHL_STATS_API_HOST="statsapi.web.nhl.com"
SEASON_START_DATE="2018-10-02"
CHECKED_TO_FILE="CHECKED_TO.txt"
HIT_MISS_FILE="HIT_MISS.txt"

def calculate_record_factor(teams)
	home_pptg = calculate_points_percentage(teams["home"])
	away_pptg = calculate_points_percentage(teams["away"])
	return home_pptg / (home_pptg + away_pptg)
end

def calculate_h2h_factor(home_id, away_id)
	home_games_played = get_completed_schedule(home_id)
	wins = 0
	games = 0
	home_games_played.each do |game|
		if game["games"][0]["teams"]["away"]["team"]["id"] == away_id
			if game["games"][0]["teams"]["away"]["score"] < game["games"][0]["teams"]["home"]["score"]
				wins += 1
			end
			games += 1
		elsif game["games"][0]["teams"]["home"]["team"]["id"] == away_id
			if game["games"][0]["teams"]["away"]["score"] > game["games"][0]["teams"]["home"]["score"]
				wins += 1
			end
			games += 1
		end
	end
	if games == 0
		return 0.5
	else
		return wins.to_f / games.to_f
	end
end

def calculate_shooting_factor(teams)
	away_stats = get_team_stats(teams["away"]["team"]["id"])
	home_stats = get_team_stats(teams["home"]["team"]["id"])
	
	shots_for_factor = home_stats["shotsPerGame"] / (home_stats["shotsPerGame"] + away_stats["shotsPerGame"])
	shots_against_factor = away_stats["shotsAllowed"] / (away_stats["shotsAllowed"] + home_stats["shotsAllowed"])
	return (shots_for_factor * 0.5) + (shots_against_factor * 0.5)
end

def calculate_special_teams_factor(teams)
	away_stats = get_team_stats(teams["away"]["team"]["id"])
	home_stats = get_team_stats(teams["home"]["team"]["id"])
	
	powerplay_factor = home_stats["powerPlayGoals"] / (home_stats["powerPlayGoals"] + away_stats["powerPlayGoals"])
	shorthanded_factor = away_stats["powerPlayGoalsAgainst"] / (away_stats["powerPlayGoalsAgainst"] + home_stats["powerPlayGoalsAgainst"])
	return (powerplay_factor * 0.5) + (shorthanded_factor * 0.5)
end

def calculate_points_percentage(team)
	w = team["leagueRecord"]["wins"]
	l = team["leagueRecord"]["losses"]
	ot = team["leagueRecord"]["ot"]
	return ((w * 2) + ot).to_f / (w + l + ot).to_f
end

def get_team_stats(id)
	response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/teams/#{id}?expand=team.stats")
	json_response = JSON.parse(response)
	return json_response["teams"][0]["teamStats"][0]["splits"][0]["stat"]
end

def get_completed_schedule(id)
    response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?teamId=#{id}&startDate=#{SEASON_START_DATE}&endDate=#{(Time.now - 86400).strftime("%Y-%m-%d")}")
	json_response = JSON.parse(response)
	return json_response["dates"]
end

def do_daily_prediction
	start_time = Time.now
	today = Time.now.strftime("%Y-%m-%d")
	if File.file?("results/#{today}.txt")
		puts "The odds for todays games have already been generated. "
		return
	end
	
	response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule")
	json_response = JSON.parse(response)
	games = json_response["dates"][0]["games"] #An array of hashes with each representing one game on tonight in the nhl
	game_results = File.open("results/#{today}.txt", 'w')
	
	games.each do |game|
		record_factor = calculate_record_factor(game["teams"])
		h2h_factor = calculate_h2h_factor(game["teams"]["home"]["team"]["id"], game["teams"]["away"]["team"]["id"])
		shots_factor = calculate_shooting_factor(game["teams"])
		special_teams_factor = calculate_special_teams_factor(game["teams"])
		strength_factor = (shots_factor + special_teams_factor + record_factor + h2h_factor) / 4
		
		puts "#{game["teams"]["away"]["team"]["name"]} @ #{game["teams"]["home"]["team"]["name"]} #{strength_factor}"
		game_results.write("#{game["gamePk"]} #{strength_factor} #{game["teams"]["away"]["team"]["name"]} @ #{game["teams"]["home"]["team"]["name"]}\n")
	end
	game_results.close
	end_time = Time.now
	puts "\nDid daily simulation of #{games.length} games in #{end_time - start_time} seconds"
end

def check_all_generated_odds
	checked_to = File.read(CHECKED_TO_FILE)
	past_results = File.read(HIT_MISS_FILE)
	results = Dir.entries("results")
	hits = past_results.split(" ")[0].to_i
	misses = past_results.split(" ")[1].to_i
	
	latest_is_today = false
	index_of_unchecked = results.length - 1
	
	while index_of_unchecked > 1
		if results[index_of_unchecked].chomp(".txt") == checked_to
			index_of_unchecked += 1
			break
		end
		index_of_unchecked -= 1
	end

	for i in (index_of_unchecked)..(results.length)
		if results[i].chomp(".txt") == Time.now.strftime("%Y-%m-%d")
			#don't want to check results for todays games, as they haven't finished yet
			latest_is_today = true
			break
		end
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?date=#{results[i].chomp(".txt")}")
		json_response = JSON.parse(response)
		daily_results = File.readlines("results/#{results[i]}")
		daily_results.each do |game|
			game_info = game.split(" ")
			json_response["dates"][0]["games"].each do |result|
				if result["gamePk"] == game_info[0].to_i
					if game_info[1].to_f >= 0.5 and result["teams"]["away"]["score"] < result["teams"]["home"]["score"]
						#correctly predicted home team wins
						hits += 1
					elsif game_info[1].to_f < 0.5 and result["teams"]["away"]["score"] > result["teams"]["home"]["score"]
						#correctly predicted away team win
						hits += 1
					else
						#failed to predict winner
						misses += 1
					end
					break
				end
			end
		end
	end
	
	check = File.open(CHECKED_TO_FILE, 'w')
	if !latest_is_today
		check.write(results[results.length - 1].chomp(".txt"))
	else
		check.write(results[results.length - 2].chomp(".txt"))
	end
	hit_miss = File.open(HIT_MISS_FILE, 'w')
	hit_miss.write("#{hits} #{misses}")
	puts "Lifetime accuracy for the system including results through yesterday is #{(hits.to_f / (hits + misses)).to_f * 100}%"
	check.close
	hit_miss.close
end


if ARGV.length > 1
	puts "Please specify on operation at a time."
elsif ARGV.length == 0
	puts "You must specify an operation"
	#Print usage
else
	case ARGV[0]
		when "-h", "--help"
			#"print usage
		when "-g", "--generate"
			do_daily_prediction
		when "-c", "--check"
			check_all_generated_odds
		when "-s", "--simulate"
			#simulate remainder of regular season
		when "-a", "--archive"
			#archive the old results files, ie move them somewhere else and maybe compress them
		else
			puts "invalid option"
			#print usage
	end
end