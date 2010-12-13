#!/usr/bin/env ruby

# Purpose: to locate the best vpn server for fast speed, esp. for veryfastvpn users on Linux and Rubyists!
# AFM: also retrieve the human readable names for the IPs by parsing the webpage.

begin
	require 'mechanize'
rescue
	puts " Please use 'gem install mechanize' to install the gem!"
end

SHOW_MAX_IPS  = 5   # how many IP will be displayed sorted by rtt
GAME_ONLY_IPS = [ "91.207.192.47", "210.175.52.11",
				   "202.133.226.233"]  # game server has speed limitation
SVRS_PAGE="https://www.veryfastvpn.com/servers.php" # list of available vpn server


def get_ips_from_webpage(link = SVRS_PAGE)
	g = Mechanize.new
	page = g.get(link) 

	content = page.body	
	# puts content

	## parse the web page
	ip_pat = /((\d{1,3}\.){3}\d{1,3})/mxi
	ips = content.scan(ip_pat)
	ips = ips.flatten
	ips.reject! { |item| item.split(".").size != 4}
	# puts ips
	return ips
end

def get_rrt_avg(ip)
	ping_cmd = "ping #{ip} -c 3 -q"
	cmd_out = ""
	IO.popen(ping_cmd){ |f|
		until f.eof?
			cmd_out += f.gets
		end
		#puts cmd_out + "<<<< "

		rtt_pat = /\d+\.{,1}\d+/
		cmd_out.each_line do | line |
			if line =~ /rtt min\/avg\/max\//  # line with rtt 
				return line.scan(rtt_pat)[2]
			end
		end
	}
	return 9999  # if not find rtt, at 
	# TODO: give max ping time if timeout
end
# puts get_rrt_avg("www.google.com")

# ping all the IPs
def collect_rtts(ips)
	#puts "total IPs found : " + ips.size.to_s
	all_pings = {}	
	tasklist = []
	ips.each do | ip |	
		task = Thread.new(ip) do  | ip| 
			rtt = get_rrt_avg(ip) 
			#puts "#{ip}  ..... #{rtt} ms "
			all_pings.store( rtt.to_i, ip )
		end
		tasklist << task
	end

	tasklist.each { | task |
		task.join
	}
	return all_pings
end

 if __FILE__ == $0 
	ips = get_ips_from_webpage()
	ips.reject! { | ip | GAME_ONLY_IPS.include? ip }
	rrts = collect_rtts(ips)
 	ll = rrts.sort
	(0..SHOW_MAX_IPS).each do | i | 
		puts ll[i][1].to_s   + ".... " + ll[i][0].to_s
	end
 end

# TODO: should audit the rtt time based on the day period

