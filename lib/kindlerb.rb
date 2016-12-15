# encoding: utf-8

# extract nav structure

require 'pathname'
require 'yaml'
require 'nokogiri'
require 'mustache'
require 'fileutils'
require 'kindlerb/version'

# monkeypatch
class String
  def shorten(max)
    length > max ? Array(self[0,max].split(/\s+/)[0..-2]).join(' ') + '...' : self
  end
end

module Kindlerb

  def self.download
    # use system kindlegen if available
    if system('kindlegen', out: :close)
      puts "Using system kindlegen"
      return
    end

    gem_path = Gem::Specification.find_by_name('kindlerb').gem_dir
    ext_dir = gem_path + '/ext/'
    bin_dir = gem_path + '/bin/'

    # Define Kindlegen download files for different OS's
    executable_filename = 'kindlegen'
    windows = false
    compressed_file = case RbConfig::CONFIG['host_os']
    when /mac|darwin/i
      extract = 'unzip '
      "KindleGen_Mac_i386_v2_9.zip"
    when /linux|cygwin/i
      extract = 'tar zxf '
      "kindlegen_linux_2.6_i386_v2_9.tar.gz"
    when /mingw32/i
      windows = true
      extract = 'unzip '
      executable_filename = 'kindlegen.exe'
      "kindlegen_win32_v2_9.zip"
    else
      STDERR.puts "Host OS is not supported!"
      exit(1)
    end

    url = 'http://kindlegen.s3.amazonaws.com/' + compressed_file

    # Download and extract the Kindlegen file into gem's /etc folder
    unless File.directory?(ext_dir)
      FileUtils.mkdir_p(ext_dir)
    end
    system 'curl ' + url + ' -o ' + ext_dir + compressed_file
    puts "Kindlegen downloaded: " + ext_dir + compressed_file
    system extract + ext_dir + compressed_file + ' -d ' + ext_dir

    # Move the executable_filename into gem's /bin folder
    unless File.directory?(bin_dir)
      FileUtils.mkdir_p(bin_dir)
    end
    moved = FileUtils.mv(ext_dir + executable_filename, bin_dir)
    puts "Kindlegen extracted to: " + bin_dir
    # Clean up ext folder
    if moved
      FileUtils.rm_rf(ext_dir)
    end

    # Give exec permissions to Kindlegen file
    exec_file = bin_dir + executable_filename
    if windows
      cmd = "icacls #{exec_file} /T /C /grant Everyone:(f)"
      system cmd
    else
      FileUtils.chmod 0754, exec_file
    end
    puts "Execution permissions granted to the user for Kindlegen executable"

  end

  # Returns the full path to executable Kindlegen file
  def self.executable
    # use system kindlegen if available
    return 'kindlegen' if system('kindlegen', out: :close)

    gem_path = Gem::Specification.find_by_name('kindlerb').gem_dir

    # Different extensions based on OS
    kindlegen = case RbConfig::CONFIG['host_os']
    when /mac|darwin/i
      "kindlegen"
    when /linux|cygwin/i
      "kindlegen"
    when /mingw32/i
      "kindlegen.exe"
    else
      return nil
    end

    exec_path = gem_path + '/bin/' + kindlegen

    return exec_path

  end

  # Used for users to check whether Kindlerb can work
  def self.kindlegen_available?
    kindlegen = self.executable
    case kindlegen
    when 'kindlegen'
      true
    when String
      File.exist?(kindlegen)
    else
      false
    end
  end

  def self.run(target_dir, verbose = false, compression_method = 'c2')
    unless self.kindlegen_available?
      STDERR.puts "Kindlegen is not available, install it with `setupkindlerb`"
      exit(1)
    end

    opf_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/opf.mustache"))
    ncx_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/ncx.mustache"))
    contents_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/contents.mustache"))
    section_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/section.mustache"))
    masthead_gif = File.join(File.dirname(__FILE__), '..', "templates/masthead.gif")
    cover_gif = File.join(File.dirname(__FILE__), '..', "templates/cover-image.gif")

    playorder = 1

    images = []
    manifest_items = []

    base_dir = Pathname.new target_dir
    document_yml = base_dir.join "_document.yml"

    unless File.exist? document_yml
      
      puts "Usage: kindlerb [target file directory]"

      abort "Missing _document.yml. Your input file tree is not structured correctly. Please read the README."
    end

    document = YAML::load_file document_yml

    document[:spine_items] = []
    section_html_files = []

    sections_all = base_dir.join "sections", "*"

    sections = Dir[sections_all].entries.sort.map.with_index {|section_dir| 
      c = File.read(Pathname.new(section_dir) + '_section.txt')
      c.force_encoding("UTF-8")
      section_title = c.strip
      articles = Dir[Pathname.new(section_dir) + '*'].entries.select {|x| File.basename(x) !~ /section/}.sort
      section_html_files << (section_html_file = (Pathname.new(section_dir) + 'section.html').to_s)
      idref = "item-#{section_dir.gsub(/\D/, '')}"

      document[:spine_items] << {:idref => idref}
      manifest_items << {
        :href => section_html_file,
        :media => "application/xhtml+xml",
        :idref => idref
      }

      s = {
        :path => section_dir,
        :title => section_title.shorten(40),
        :playorder => (playorder += 1),
        :idref => idref,
        :href => Pathname.new(section_dir) + 'section.html',
        :articles => articles.map {|article_file|
              doc = Nokogiri::HTML(File.read(article_file, :encoding => 'UTF-8'))
              article_images = doc.search("img").map {|img| 
                mimetype =  img[:src] ? "image/#{File.extname(img[:src]).sub('.', '')}" : nil
                {:href => img[:src], :mimetype => mimetype}
              }
              images.push *article_images
              title = doc.search("html/head/title").map(&:inner_text).first || "no title"
              idref = "item-#{article_file.gsub(/\D/, '')}"
              document[:spine_items] << {:idref => idref}
              article = {
                :file => article_file,
                :href => article_file,
                :title => title, 
                :short_title => title.shorten(60),
                :author => doc.search("html/head/meta[@name=author]").map{|n|n[:content]}.first,
                :description => doc.search("html/head/meta[@name=description]").map{|n|n[:content]}.first,
                :playorder => (playorder += 1),
                :idref => idref
              }
              manifest_items << {
                :href => article[:file],
                :media => "application/xhtml+xml",
                :idref => article[:idref]
              }
              article
          }
      }

      # Generate the section html
      out = Mustache.render section_template, s
      File.open(section_html_file, "w") {|f| f.puts out}
      s

    }

    document[:first_article] = sections[0][:articles][0]
    document['sections'] = sections


    document[:manifest_items] = manifest_items + images.map.with_index {|img, idx| 
      {
        :href => img[:href],
        :media => img[:mimetype],
        :idref => "img-%03d" % idx
      }
    } 
    document[:cover_mimetype] ||= "image/gif"
   
    opf = Mustache.render opf_template, document
    opf_path = base_dir.join "kindlerb.opf"
    File.open(opf_path, "w") {|f| f.puts opf}
    puts "Wrote #{target_dir}/kindlerb.opf"

    # NCX
    ncx = Mustache.render ncx_template, document
    ncx_path = base_dir.join "nav-contents.ncx"
    File.open(ncx_path, "w") {|f| f.puts ncx}
    puts "Wrote #{target_dir}/nav-contents.ncx"

    # contents
    contents = Mustache.render contents_template, document
    contents_path = base_dir.join "contents.html"
    File.open(contents_path, "w") {|f| f.puts contents}
    puts "Wrote #{target_dir}/contents.html"

    outfile = document['mobi_outfile'] 
    infile = base_dir.join "kindlerb.opf"
    puts "Writing #{outfile}"
    cmd = self.executable + "#{' -verbose' if verbose} -#{compression_method} -o #{outfile} #{infile} && echo 'Wrote MOBI to #{outfile}'"
    puts cmd
    system cmd

    # If the system call returns anything other than nil, the call was successful
    # Because Kindlegen completes build successfully with warnings
    successful = $?.exitstatus.nil? ? false : true
    if successful
      return true
    else
      return false
    end

  end
end
