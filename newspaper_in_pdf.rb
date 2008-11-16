# 'Newspaper In PDF'  (licensed under GPL)
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

## Abstract class - with all subclasses implement the abstract methods. 
class NewspaperInPDF

## Define the pdf filename rules, which should be a string of regular expression.
def self.get_normal_formats
	raise "call abstract method 'self.get_normal_format', please implement it in the subclass!"
end

## Define how to get the section+page from the filename
def self.get_section_page filename
	raise "call abstract method 'self.process_name (filename)', please implement it in the subclass!"
end

## Found a name for the file if the pdf file is normally named.
def self.name_it_by_section_page original_name
	if is_normal_pdf_name original_name
		sect_page_name = get_section_page(original_name)
	else 
		sect_page_name = original_name
	end
	return sect_page_name + ".pdf"
end

## Decide if the filename is the same as the assumed.
def self.is_normal_pdf_name filename
	get_normal_formats.each do |format|
		if filename =~ /#{format}/
			return true
		else 
			next
		end
	end
	return false
end

end  # of class NewspaperInPDF


class YangtseEveningPost < NewspaperInPDF

def self.get_normal_formats
	# YangtseEP has two kinds of recognizable pdf filename format for edition AB & C
	normal_formats = []
	unknown_encoding = "[0-9]*"	
	page_idx_fmt = "YZ[A-E]?[0-9]{2}" 	
	assumed_date_encoding = "b[0-9]{2}C" #  little evidence showing the date
	normal_name_format_ediAB = "#{unknown_encoding}#{page_idx_fmt}#{assumed_date_encoding}"

	unknown_encoding = "[0-9]{13}"
	page_idx_fmt = "C[0-9]{2}"
	normal_name_format_ediC = "#{unknown_encoding}#{page_idx_fmt}"
	
	normal_formats << normal_name_format_ediAB
	normal_formats << normal_name_format_ediC	
	return normal_formats
end

def self.get_section_page filename

	unknown_encoding = "[0-9]*"	
	page_idx_fmt = "YZ[A-E]?[0-9]{2}" 	
	assumed_date_encoding = "b[0-9]{2}C" #  little evidence showing the date
	normal_name_format_ediAB = "#{unknown_encoding}#{page_idx_fmt}#{assumed_date_encoding}"

	unknown_encoding = "[0-9]{13}"
	page_idx_fmt = "C[0-9]{2}"
	normal_name_format_ediC = "#{unknown_encoding}#{page_idx_fmt}"

	## TODO:Dulplicated code, magic number
	if filename =~ /#{normal_name_format_ediAB}/
		return filename.slice( filename.index("YZ") + 2 , 3 )
	elsif filename =~ /#{normal_name_format_ediC}/
		return filename.slice( filename.index("C"), 3 )
	else
		raise "Caught irregular filename: [" +  filename + "]"
	end
end

end #of class YangtseEveningPost


class XinminNightly < NewspaperInPDF

## normal_name_format = "XM[0-9]{6}[A-Z][0-9]{3}"
def self.get_normal_formats
	symbol = "XM"
	date_fmt = "[0-9]{6}" # find a better one
	section = "[A-Z]"
	page = "[0-9]{3}"
	normal_name_format = "#{symbol}#{date_fmt}#{section}#{page}"
	return ["#{normal_name_format}"]
end

def self.get_section_page filename
	return	filename.slice( 8 , 4 )
end

end #of class XinminNightly


class NewspaperToolSet

attr_accessor :target_dir, :specific_date

## Get the ONE webpage which contains all the pdfs links.
def get_pdfs_webpage_urlstr
	raise "call abstract method 'get_pdfs_webpage_urlstr', please implement it in the subclass!"
end

## Toolset will generate many file/directory according to different newspapers, symbol is used for identification.
def get_newspaper_sym
	raise "call abstract method 'get_newspaper_sym', please implement it in the subclass!"
end

## different subclasses have different ways of getting names=>new_name mapping.
def get_name_mapping(pdfs_filename)
	raise "call abstract method 'get_name_mapping(pdfs_filename)', please implement it in the subclass!"
end

## different subclasses have different ways of parsing old filename and turning to new one.
def normalized_name(name)
	raise "call abstract method 'normalized_name(name)', please implement it in the subclass!"
end

#TODO: define some rules limiting time range for download, i.e. some newspaper should be download afternoon when it is published.

def download
	src_url = get_pdfs_webpage_urlstr  ;	puts src_url

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
	# p(pdf_urls)

	## should NOT be apparent to the user.
	urls_file = "#{get_newspaper_sym}#{self.object_id}"	## same file not allowing the multithreading, ensure singularity.
	f = File.new(urls_file , "w") ; f.puts pdf_urls ; f.close
	repo = target_dir   ;# puts repo
	system("wget -i " + urls_file +" -P " + repo)	## download using wget tool
	File.delete urls_file if File.exists? urls_file	## clean
end

## 
def rename
	if File.directory? target_dir 
		Dir.chdir target_dir
		pdfs = Dir.glob("*.pdf")
	
		names_map = get_name_mapping(pdfs)	 ;#       p names_map
		rename_by_names_mapping(names_map) ;#	  p names_map
	else
		# TODO: throw exception for handling
		
	end 
end

def merge_to_one_pdf
	Dir.chdir target_dir
	timestamp = specific_date.year.to_s + "-" + specific_date.month.to_s + "-" + specific_date.strftime('%d')# e.g. 2008-11-08

	system("pdftk *.pdf output " + timestamp.to_s + "AllInOne.pdf")
end

## Shared methods
def rename_by_names_mapping(names_map)
	Dir.chdir target_dir
	
	names_map.each_pair do  | src_name , target_name |
		File.rename(src_name, target_name )
	end
end

end # of class NewspaperToolSet


class XinminNightlyToolset < NewspaperToolSet

def get_pdfs_webpage_urlstr
	# url_folder = "http://pdf.news365.com.cn/xmpdf"  # if we get pdf's url from src_url, no need of this variable
	yr_mth_day = specific_date.year.to_s + specific_date.month.to_s + specific_date.strftime('%d') # Date.today.strftime('%d') # e.g. 20081109
	src_url = "http://pdf.news365.com.cn/xmpdf/default.asp?nowDay=#{yr_mth_day}"
	return src_url
end

## Toolset will generate many file/directory according to different newspapers, symbol is used for identification.
def get_newspaper_sym
	"XM"
end

def get_name_mapping pdfs_filename 
	names_mapping = {}
	pdfs_filename.each do | pdf |
		if XinminNightly.is_normal_pdf_name pdf
			names_mapping.store(pdf, normalized_name(pdf))	
		else
			## process the irregulars after all normals processed
	       		## introduce human intervention
			puts "Please assign the page ( e.g. A99) to this irregular page, " + pdf
	       		puts "You may open the pdf file to assure the edition and the page number."
			input = gets #STDIN.getc 
	    		#TODO: sanity checking the 'input' and avoid the same value in case of renaming to same file name.
			# input = input.chomp + "-1" if input.chomp.has_value? input.chomp
	                names_mapping.store(pdf, input.chomp.to_s + ".pdf")
		end
	end
	
	return names_mapping
end

# get 'section-page' value
def normalized_name(name)
	XinminNightly.name_it_by_section_page(name)	
end

end # of class XinminNightlyToolset


class YangtseEveningPostToolset < NewspaperToolSet

def get_pdfs_webpage_urlstr
	yr_mth = specific_date.year.to_s + "-" + specific_date.month.to_s # e.g. 2008-11
	day = specific_date.strftime('%d') 
	puts yr_mth # ; puts day
	url = "http://epaper.yangtse.com/yzwb/"+ yr_mth +"/"+ day + "/node_4109.htm" 
	return url
end

def get_newspaper_sym
	"YZ"
end

def get_name_mapping(pdfs_filename)
	names_mapping = {}
	pdfs_filename.each do | pdf |
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

## different subclasses have different ways of parsing old filename and turning to new one.
def normalized_name(name)
	YangtseEveningPost.name_it_by_section_page(name)
end

end # of class YangtseEveningPostToolset


# for test
if __FILE__ == $0
	
	clock = Time.new
	if clock.hour >= 16
		todaynp = XinminNightlyToolset.new
		todaynp.specific_date = Date.today  # ; puts todaynp.specific_date.to_s ; puts "#####"
		todaynp.target_dir=File.expand_path(File.join("~", "newspapers", "wenhui", todaynp.specific_date.to_s))
		todaynp.download
		todaynp.rename
		todaynp.merge_to_one_pdf
	end
	if clock.hour > 8 && clock.hour < 16 
		## download yangtse
		todaynp = YangtseEveningPostToolset.new
		todaynp.specific_date = Date.today # ; puts todaynp.specific_date.to_s ; puts "#####"
		todaynp.target_dir=File.expand_path(File.join("~", "newspapers", "yangtse", todaynp.specific_date.to_s))
		todaynp.download
		todaynp.rename
		todaynp.merge_to_one_pdf
		
	end
	
end

#TODO: dir creation at first run and related exception
#TODO: download rule according to the publishing time
#TODO: in NewspaperToolset#download, 
