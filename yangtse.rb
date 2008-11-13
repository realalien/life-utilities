# 'Yangtse Evening Post AllinOne Pager' v.1.0 (licensed under GPL)
# ##############################################################################
# maintainer: neilalaer@gmail.com
#
# INSTALL GUIDE (for Linux only)
#	* ruby 
#	* gem install htree
#	* sudo apt-get install pdftk, wget
# ##############################################################################
# Due to unknown encoding of files, parse the file name and rename to a seq.
# usually, standard name is formatted in '<numbers> + YZ + <page> + <date> + C'
# The steps of process, suggested:
# * make sure the date
# * rename to A[B,C]+<page_number>
# * merge into one file
require 'date'
require 'pp'

require 'date'
require 'open-uri'
require 'rexml/document'
require 'htree'
require 'fileutils'

class YangtseEveningPost

# There is no simple way to figure out whether the pdf newspapers has changed name or not, naively I assume a format from a group of file
# Or we should sense the change.

def self.is_normal_pdf_name name
	##  when renaming today's newspaper
	#	normal_name_format = "[0-9]*YZ[A-E]?[0-9]{2}b#{Date.today.strftime("%d")}C"
	assumed_encoding = "[0-9]*"	
	page_idx_fmt = "YZ[A-E]?[0-9]{2}" 	
	date_encoding = "b[0-9]{2}C" 
	normal_name_format = "#{assumed_encoding}#{page_idx_fmt}#{date_encoding}"
	if name =~ /#{normal_name_format}/
		return true
	else
		return false
	end
end

# slice the page name, e.g. B03 - B section 03 page,
def self.named_by_pages name
	if is_normal_pdf_name name
		page_name = name.slice( name.index("YZ") + 2 , 3 )
	else 
		page_name = name
	end
	return page_name + ".pdf"
end
	
end #of class YangtseEveningPost

class WenhuiDaily

# There is no simple way to figure out whether the pdf newspapers has changed name or not, naively I assume a format from a group of file
# Or we should sense the change.

def self.is_normal_pdf_name name
	##  when renaming today's newspaper
	#	normal_name_format = "XM[0-9]{6}[A-Z][0-9]{3}"
	symbol = "XM"
	date_fmt = "[0-9]{6}" # find a better one
	section = "[A-Z]"
	page = "[0-9]{3}"
	normal_name_format = "#{symbol}#{date_fmt}#{section}#{page}"
	if name =~ /#{normal_name_format}/
		return true
	else
		return false
	end
end

# slice the page name, e.g. B03 - B section 03 page,
def self.named_by_section_page name
	if is_normal_pdf_name name
		page_name = name.slice( 8 , 4 )
	else 
		page_name = name
	end
	return page_name + ".pdf"
end
	
end #of class WenhuiDaily



class WenhuiDailyToolset

def self.rename_wenhui_pages(path)
	if File.directory? path 
		Dir.chdir path

		pdfs = Dir.glob("*.pdf")
	
		names_map = get_name_mapping(pdfs)
		#       p names_map
		rename_by_names_mapping(path, names_map)
		#	p names_map
	else
		# TODO: throw exception for handling
		
	end 

end

def self.get_name_mapping pdfs 
	names_mapping = {}
	pdfs.each do | pdf |
		if WenhuiDaily.is_normal_pdf_name pdf
			names_mapping.store(pdf, normalized_name(pdf))	
		else
			## process the irregulars after all normals processed
	       		## introduce human intervention
			puts "Please assign the page ( e.g. A99) to this irregular page, " + pdf
	       		puts "You may open the pdf file to assure."
			input = gets #STDIN.getc 
	    		#TODO: sanity checking the 'input' and avoid the same value in case of renaming to same file name.
			# input = input.chomp + "-1" if input.chomp.has_value? input.chomp
	                names_mapping.store(pdf, input.chomp.to_s + ".pdf")
		end
	end
	
	return names_mapping
end

# get 'section-page' value
def self.normalized_name(name)
	WenhuiDaily.named_by_section_page(name)	
end

def self.rename_by_names_mapping(path, names_map)
	Dir.chdir path
	
	names_map.each_pair do  | src_name , target_name |
		File.rename(src_name, target_name )
	end
end

########
def self.download_wenhui(target_dir, date=Date.today.to_s)
	# url_folder = "http://pdf.news365.com.cn/xmpdf"  # if we get pdf's url from src_url, no need of this variable
	specific_date = Date.strptime(date)
	#TODO: exception handle

	yr_mth_day = specific_date.year.to_s + specific_date.month.to_s + specific_date.strftime('%d') # Date.today.strftime('%d') # e.g. 20081109
	
	src_url = "http://pdf.news365.com.cn/xmpdf/default.asp?nowDay=#{yr_mth_day}"
	
	puts src_url
	pdf_urls = []

	open(src_url) {
		 |page| page_content = page.read()
		 doc = HTree(page_content).to_rexml
		 doc.root.each_element('//a')  do |elem |
			puts elem
			a = elem.attribute("href").value
			if a =~ /.pdf$/
				pdf_urls << File.join(src_url.slice(0,src_url.rindex('/')),a)
				pdf_urls.uniq!
			end
		end
	}
	p(pdf_urls)
	f = File.new("tt.txt", "w") ; f.puts pdf_urls ; f.close

	# download
	repo = target_dir
	# puts repo
	system("wget -i tt.txt -P "+repo)
	# TODO: clean the file
	File.delete "tt.txt" if File.exists? "tt.txt"
end

def self.merge_to_one_pdf(target_dir)
	Dir.chdir target_dir
	timestamp = Date.today.year.to_s + "-" + Date.today.month.to_s + "-" + Date.today.strftime('%d')# e.g. 2008-11-08

	system("pdftk *.pdf output " + timestamp.to_s + "AllInOne.pdf")
end

end # of class WenhuiDailyToolset

class YangtseEveningPostToolset

def self.rename_yangtse_pages(path)
	if File.directory? path 
		Dir.chdir path

		pdfs = Dir.glob("*.pdf")
	
		names_map = get_name_mapping(pdfs)
		#       p names_map
		rename_by_names_mapping(path, names_map)
		#	p names_map
	else
		# TODO: throw exception for handling
		
	end 
end

# To parse and rename the pdf pages of 'Yangtse Evening Post' 
# in format '<numbers> + YZ + <page> + <date> + C'
def self.get_name_mapping pdfs 
	names_mapping = {}
	pdfs.each do | pdf |
		if YangtseEveningPost.is_normal_pdf_name pdf
			names_mapping.store(pdf, normalized_name(pdf))	
		else
			## process the irregulars after all normals processed
	       		## introduce human intervention
			puts "Please assign the page ( e.g. A99) to this irregular page, " + pdf
	       		puts "You may open the pdf file to assure."
			input = gets #STDIN.getc 
	    		#TODO: sanity checking the 'input' and avoid the same value in case of renaming to same file name.
			# input = input.chomp + "-1" if input.chomp.has_value? input.chomp
	                names_mapping.store(pdf, input.chomp.to_s + ".pdf")
		end
	end
	
	return names_mapping
end

def self.normalized_name(name)
	YangtseEveningPost.named_by_pages(name)	
end


def self.rename_by_names_mapping(path, names_map)
	Dir.chdir path
	
	names_map.each_pair do  | src_name , target_name |
		File.rename(src_name, target_name )
	end

end



#######

# date should be formatted as '09' with two digits.
def self.download_yangtse(target_dir,date=Date.today)
	# url_folder = "http://epaper.yangtse.com/images" # if we get pdf's url from src_url, no need of this variable
	specific_date = Date.strptime(date)

	yr_mth = specific_date.year.to_s + "-" + specific_date.month.to_s # e.g. 2008-11
	day = specific_date.strftime('%d') 

	url = "http://epaper.yangtse.com/yzwb/"+ yr_mth +"/"+ day + "/node_4109.htm" 

	#retrieve pdfs' URLs for downloading
	urls = []
	open(url) {
	  |page| page_content = page.read()
	 doc = HTree(page_content).to_rexml
	 doc.root.each_element('//a')  do |elem |
		a = elem.attribute("href").value
		if a =~ /.pdf$/
			urls << File.join(url.slice(0,url.rindex('/')),a)
			urls.uniq!
		end
	end
	}

	f = File.new("tt.txt", "w") ; f.puts(urls) ; f.close

	# download
	repo = target_dir
	# puts repo
	system("wget -i tt.txt -P "+repo)
	# TODO: clean the file
	File.delete "tt.txt" if File.exists? "tt.txt"

end

def self.merge_to_one_pdf(target_dir)
	Dir.chdir target_dir
	timestamp = Date.today.year.to_s + "-" + Date.today.month.to_s + "-" + Date.today.strftime('%d')# e.g. 2008-11-08

	system("pdftk *.pdf output " + timestamp.to_s + "AllInOne.pdf")
end

end # of class YangtseEveningPostToolset


# for test
if __FILE__ == $0
	#str = "1226167650156YZA01b09C.pdf"
	#puts YangtseEveningPost.is_normal_pdf_name str 
	#puts YangtseEveningPost.named_by_pages str 

	#rename_yangtse_pages("./")

	clock = Time.new
	if clock.hour > 8
	## download yangtse
	specific_date = Date.today.to_s
	target_dir = File.expand_path(File.join("~", "newspapers", "yangtse", specific_date ))
	YangtseEveningPostToolset.download_yangtse(target_dir,specific_date )
	YangtseEveningPostToolset.rename_yangtse_pages(target_dir)
	YangtseEveningPostToolset.merge_to_one_pdf(target_dir)
	end
	
	if clock.hour > 16
	# download wenhui
	target_dir = File.expand_path(File.join("~", "newspapers", "wenhui", specific_date ))
	WenhuiDailyToolset.download_wenhui(target_dir, specific_date)
	WenhuiDailyToolset.rename_wenhui_pages(target_dir)
	WenhuiDailyToolset.merge_to_one_pdf(target_dir)
	end
end
