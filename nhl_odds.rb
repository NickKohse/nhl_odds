require 'net/http'
require 'json'

require_relative 'team_strength.rb'
require_relative 'team_compare.rb'
require_relative 'constants.rb'

def do_daily_prediction
	start_time = Time.now
	today = Time.now.strftime("%Y-%m-%d")
	if File.file?("results/#{today}.txt")
		puts "The odds for todays games have already been generated. "
		return
	end
	
	response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?date=#{today}")
	json_response = JSON.parse(response)
	
	if json_response["dates"].length == 0
		puts "No games today ... exiting"
		return
	end
	
	games = json_response["dates"][0]["games"] #An array of hashes with each representing one game on tonight in the nhl
	game_results = File.open("results/#{today}.txt", 'w')
	
	games.each do |game|
		'''
		record_factor = calculate_record_factor(game["teams"])
		h2h_factor = calculate_h2h_factor(game["teams"]["home"]["team"]["id"], game["teams"]["away"]["team"]["id"])
		shots_factor = calculate_shooting_factor(game["teams"])
		special_teams_factor = calculate_special_teams_factor(game["teams"])
		'''
		home = Team_Strength.new(game["teams"]["home"]["team"]["id"])
		away = Team_Strength.new(game["teams"]["away"]["team"]["id"])
		matchup = Team_Compare.new(home, away)
		strength_factor = matchup.compare #(shots_factor + special_teams_factor + record_factor + h2h_factor) / 4
		
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

	for i in (index_of_unchecked)..(results.length - 1)
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