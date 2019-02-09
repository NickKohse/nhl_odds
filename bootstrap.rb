puts "Checking if correct file structure exists..."

unless File.file?("CHECKED_TO.txt")
	puts "No CHECKED_TO file, creating a new one..."
	File.open("CHECKED_TO.txt", "w") { |f| f.write("#{(Time.now - 86400).strftime("%Y-%m-%d")}")}
end

unless File.file?("HIT_MISS.txt")
	puts "No HIT_MISS file, creating a new one..."
	File.open("HIT_MISS.txt", "w") { |f| f.write("0 0")}
end

unless File.exist?("results")
	puts "No results directory, creating one..."
	Dir.mkdir("results")
end

puts "Bootstrap complete!"