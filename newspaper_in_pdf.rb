#!/usr/bin/env ruby 
#
## == Synopsis 
##   A tool for downloading specific newspapers and merge into one file. 
##
## == Examples
##   ruby newspaper_in_pdf.rb -1 whb	
## 					#day_offset => -1, newspaper => 'whb'
##   ruby newspaper_in_pdf.rb xm	
##					# day_offset => 0, newspaper => 'xm'
##   ruby newspaper_in_pdf.rb xm whb    
##					# day_offset => 0, newspaper => ['xm','whb'] 
##   ruby newspaper_in_pdf.rb 		
##					# day_offset => 0, newspaper => :all
##
##   Other examples:
##     ruby newspaper_in_pdf.rb -q   
##					# day_offset => 0, newspaper => :all 
##     ruby --verbose newspaper_in_pdf.rb 
##
## == Usage 
##   ruby newspaper_in_pdf.rb [options] 
##   For help use: ruby newspaper_in_pdf.rb -h
##
## == Options
##   -h, --help          Displays help message
##   -v, --version       Display the version, then exit
##   -q, --quiet         Output as little as possible, overrides verbose
##   -V, --verbose       Verbose output
##   TO DO - add additional options
##
## == Author
##   Realalien (realalienATgmail.com) 
##
## == Copyright
##   Licensed under the GPLv3 License:
##   http://www.opensource.org/licenses/mit-license.php

# ##############################################################################
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
# encoding: UTF-8
require 'rubygems'
require 'date'
require 'pp'

require 'open-uri'
require 'rexml/document'
require 'htree'
require 'fileutils'

require 'optparse' 
require 'ostruct'


Encoding.default_external = 'utf-8'
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
    assumed_date_encoding = "[b|c|B|C|][0-9]{2}[c|C]" #  little evidence showing the date
    normal_name_format_ediAB = "#{unknown_encoding}#{page_idx_fmt}#{assumed_date_encoding}"
    
    unknown_encoding = "[0-9]{13}"
    page_idx_fmt = "C[0-9]{2}"
    normal_name_format_ediC = "#{unknown_encoding}#{page_idx_fmt}"
    
    unknown_encoding = "[0-9]{13}"
    page_idx_fmt = "YZ[A-E]?[0-9]{2}"
    unknown_encoding = "[0-9]{3}[C|c]"
    normal_name_format_edi2009 = "#{unknown_encoding}#{page_idx_fmt}#{unknown_encoding}"
    
    normal_formats << normal_name_format_ediAB
    normal_formats << normal_name_format_ediC	
    normal_formats << normal_name_format_edi2009
    return normal_formats
  end
  
  def self.get_section_page filename
    
    unknown_encoding = "[0-9]*"	
    page_idx_fmt = "YZ[A-E]?[0-9]{2}" 	
    assumed_date_encoding = "[b|B|C|c][0-9]{2}[C|c]" #  little evidence showing the date
    normal_name_format_ediAB = "#{unknown_encoding}#{page_idx_fmt}#{assumed_date_encoding}"
    
    unknown_encoding = "[0-9]{13}"
    page_idx_fmt = "C[0-9]{2}"
    normal_name_format_ediC = "#{unknown_encoding}#{page_idx_fmt}"
    
    unknown_encoding = "[0-9]{13}"
    page_idx_fmt = "YZ[A-E]?[0-9]{2}"
    unknown_encoding = "[0-9]{3}[C|c]"
    normal_name_format_edi2009 = "#{unknown_encoding}#{page_idx_fmt}#{unknown_encoding}"
    
    
    ## TODO:Dulplicated code, magic number
    if filename =~ /#{normal_name_format_ediAB}/
      return filename.slice( filename.index("YZ") + 2 , 3 )
    elsif filename =~ /#{normal_name_format_ediC}/
      return filename.slice( filename.index("C"), 3 )
    elsif filename =~ /#{normal_name_format_edi2009}/
      return filename.slice( filename.index("YZ") + 2 , 3 )
    else
      raise "Caught irregular filename: [" +  filename + "]"
    end
  end
  
end #of class YangtseEveningPost

##Notice: Wenhui Daily has no section named in pdf filename
class WenhuiDaily < NewspaperInPDF
  
  ## normal_name_format = "XM[0-9]{6}[A-Z][0-9]{3}"
  def self.get_normal_formats
    symbol = "WH"
    date_fmt = "[0-9]{6}" # find a better one
    #	section = "[A-Z]" 
    page = "[0-9]{2}"
    normal_name_format = "#{symbol}#{date_fmt}#{page}"
    return ["#{normal_name_format}"]
  end
  
  def self.get_section_page filename
    return	filename.slice( 8 , 2 )
  end
  
end #of class WenhuiDaily

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
    return  filename.slice( 8 , 4 )
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
    #TODO: add time frame for downloading at a specific time
    src_url = get_pdfs_webpage_urlstr  ;	# puts src_url
    
    pdf_urls = []
    begin
      open(src_url) {
        |page| page_content = page.read().force_encoding("ISO-8859-1").encode("UTF-8")
        doc = HTree(page_content).to_rexml
        doc.root.each_element('//a')  do |elem |
          #puts elem
          a = elem.attribute("href").value
          if a =~ /.pdf$/
            pdf_urls << File.join(src_url.slice(0,src_url.rindex('/')),a)
            pdf_urls.uniq!
          end
        end
      }
      # p(pdf_urls)
    rescue
      puts "#{src_url} failed to open!"	
      raise "please check URL #{src_url}"	
    end
    
    ## should NOT be apparent to the user.
    urls_file = "#{get_newspaper_sym}#{self.object_id}"	## same file not allowing the multithreading, ensure singularity.
    f = File.new(urls_file , "w") ; f.puts pdf_urls ; f.close
    repo = target_dir   ;# puts repo
    system("wget -nv -i " + urls_file +" -P " + repo)	## download using wget tool
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
    #yr_mth_day = specific_date.year.to_s + specific_date.month.to_s + specific_date.strftime('%d') # Date.today.strftime('%d') # e.g. 20081109
    #src_url = "http://pdf.news365.com.cn/xmpdf/default.asp?nowDay=#{yr_mth_day}"
    # src_url="http://xinmin.news365.com.cn/pdf/default.asp"
    src_url= "http://pdf.news365.com.cn/xmpdf/default.asp"
    return src_url
  end
  
  ## Toolset will generate many file/directory according to different newspapers, symbol is used for identification.
  def get_newspaper_sym
	"XM"
  end
  
  def get_name_mapping pdfs_filename 
    names_mapping = {}
    pdfs_filename.each do | pdf |
      begin
        if XinminNightly.is_normal_pdf_name pdf
          names_mapping.store(pdf, normalized_name(pdf))	
        else
          ## write to a single file
          file   = File.open("~/newspapers/irregular.log", File::WRONLY|File::APPEND|File::CREAT) 
          file.puts "#{Time.now.strftime('%m/%d/%Y')}\t#{get_newspaper_sym}\t#{pdf}"
          
          file.close	
          ## process the irregulars after all normals processed
          ## introduce human intervention
          puts "Please assign the page ( e.g. A99) to this irregular page, " + pdf
          puts "You may open the pdf file to assure the edition and the page number."
          input = gets #STDIN.getc 
          #TODO: sanity checking the 'input' and avoid the same value in case of renaming to same file name.
          # input = input.chomp + "-1" if input.chomp.has_value? input.chomp
          names_mapping.store(pdf, input.chomp.to_s + ".pdf")
        end
      rescue
        next
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
    yr_mth = specific_date.year.to_s + "-" + specific_date.strftime("%m") # e.g. 2008-11
    day = specific_date.strftime('%d') 
    #puts yr_mth # ; puts day
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
        ## write to a single file
        
        ## process the irregulars after all normals processed
        ## introduce human intervention
        puts "Please assign the page ( e.g. A99) to this irregular page, " + pdf
        puts "You may open the pdf file to assure."
        input = gets #STDIN.getc 
        #TODO: sanity checking the 'input' and avoid the same value in case of renaming to same file name.
        # input = input.chomp + "-1" if input.chomp.has_value? input.chomp
        file   = File.open(File.expand_path("~/newspapers/irregular.log"), File::WRONLY|File::APPEND|File::CREAT)
        file.puts "#{Time.now.strftime('%m/%d/%Y')}\t#{get_newspaper_sym}\t#{pdf}=>#{input.chomp.to_s}.pdf\tSUPPOSE FORMAT:#{YangtseEveningPost.get_normal_formats}"
        file.close
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



class WenhuiDailyToolset < NewspaperToolSet
  
  def get_pdfs_webpage_urlstr
    #src_url = "http://wenhui.news365.com.cn/whb/pdf/default.asp"
    src_url = "http://pdf.news365.com.cn/whpdf/default.asp"
    return src_url
  end
  
  ## Toolset will generate many file/directory according to different newspapers, symbol is used for identification.
  def get_newspaper_sym
	"WH"
  end
  
  def get_name_mapping pdfs_filename 
    names_mapping = {}
    pdfs_filename.each do | pdf |
      if WenhuiDaily.is_normal_pdf_name pdf
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
    WenhuiDaily.name_it_by_section_page(name)	
  end
  
end # of class WenhuiDailyToolset



## Command line application wrapper
## source: http://blog.infinitered.com/entries/show/5
## source: http://www.ruby-doc.org/docs/ProgrammingRuby/html/rubyworld.html
## source: http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/index.html
class App
  VERSION = '1.0.0'
  
  attr_reader :options
  
  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = true  #TODO: once stable, change to false
    @options.quiet = false
    @options.day_offset = 0
    @options.newspapers = []
    # TODO - add additional defaults
  end
  
  # Parse options, check arguments, then process the command
  def run
    # puts "parsed_options?  >>> #{parsed_options?}"
    # puts "arguments_valid?   >>> #{arguments_valid?}"
    if parsed_options? && arguments_valid? 
      
      puts "Start at #{DateTime.now}\n\n" if @options.verbose
      
      process_arguments   
      
      output_options if @options.verbose # [Optional]
      
      process_command
      
      puts "\nFinished at #{DateTime.now}" if @options.verbose
      
    else
      output_usage
    end
    
  end
  
  protected
  
  def parsed_options?
    
    # Specify options
    opts = OptionParser.new do |opts |
      opts.banner = "Usage: ruby newspaper_in_pdf.rb [options]"
      opts.on('-v', '--version')    { output_version ; exit 0 }
      opts.on('-h', '--help')       { output_help }
      opts.on('-V', '--verbose')    { @options.verbose = true } 
      opts.on('-q', '--quiet')      { @options.quiet = true }
      
      opts.on('-l', '--list AA,BB,CC', Array,  'The list of to-be-download newspapers' )  do | list | 
        @options.newspapers = list
      end
      opts.on('-d N', '--day-offset N', Integer,  'Determine the specific date by offseting' )  do | n |
        @options.day_offset = n
      end
      # TODO - add additional options
    end
    
    opts.parse!(@arguments) rescue return false
    process_options
    true      
  end
  
  # Performs post-parse processing on options
  def process_options
    
    
    @options.verbose = false if @options.quiet
  end
  
  def output_options
    puts "Options:\n"
    
    @options.marshal_dump.each do |name, val|        
      puts "  #{name} = #{val}"
    end
  end
  
  # True if required arguments were provided
  def arguments_valid?
    # TODO - implement your real logic here
    true # if @arguments.length == 1 
  end
  
  # Setup the arguments  #TODO: what's the difference between process_options()
  def process_arguments
    # clean unsupport symbols, e.g. JieFang;
    # or error argument due to option typo, e.g. '-list' will put  'ist' into the array in this src.
    @support_newspapers  = Array.new  #TODO: move to elsewhere
    @support_newspapers << :XM
    @support_newspapers << :WHB
    @support_newspapers << :YZ
    # ATTENTION: command line input is an array of string, to be consistent, internally I use only symbol when using this symbol
    @options.newspapers = @options.newspapers.collect { | item | item.to_sym } & @support_newspapers
    
    if @options.newspapers.size == 0
      @support_newspapers.each do | sym |
        @options.newspapers << sym
      end 
    end
  end
  
  def output_help
    output_version
    #RDoc::usage() #exits app
  end
  
  def output_usage
    #RDoc::usage('Usage') # gets usage from comments above
  end
  
  def output_version
    puts "#{File.basename(__FILE__)} version #{VERSION}"
  end
  
  def disk_free_space_in_MB( path )
    `df -P #{path} |grep ^/ | awk '{print $4;}'`.to_i * 1 /  1024
  end
  
  def process_command
    spec_day =  Date.today  + @options.day_offset
    clock = Time.new
    
    # TODO - do whatever this app does, e.g. module
    sym_to_toolset_map = { :XM => "XinminNightlyToolset" , :WHB => "WenhuiDailyToolset", :YZ => "YangtseEveningPostToolset" }
    sym_to_folder_map = { :XM => "xinmin" , :WHB => "wenhui", :YZ => "yangtse" }
    
    if disk_free_space_in_MB("/home/realalien/newspapers") < 200	
      puts "Disk quota is too small, please free more space"
    else
      puts "Starting ..."
      @options.newspapers.each do | sym |
        begin 
          klass = sym_to_toolset_map.fetch(sym)
          todaynp = inst = Kernel.const_get(klass).new
          todaynp.specific_date = spec_day
          #puts "#{todaynp.specific_date.to_s}" ;	#raise "look up the date"
          todaynp.target_dir=File.expand_path(File.join("~", "newspapers", sym_to_folder_map.fetch(sym), todaynp.specific_date.to_s))
          puts todaynp.target_dir
          todaynp.download
          todaynp.rename
          todaynp.merge_to_one_pdf 
        rescue 
          next
        end 
      end
    end	
    #process_standard_input # [Optional]
  end
  
  # not in use
  def process_standard_input
    input = @stdin.read      
  end
end


# Create and run the application
app = App.new(ARGV, STDIN)
app.run

#TODO: log the irregular pages by writing to a file, for later analysis.  need revising.
#TODO: more user-friendly
#TODO: interruption handle, e.g. no other process if stop 
#TODO: Suppress the STDOUT of system(), but with downloading info
#TODO: Avoid re-download
#TODO: clock facility and shell script to automated download,  according to the publishing time
