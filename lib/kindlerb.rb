=begin

kindlerb

kindlerb converts a file tree of sections, articles, images, and metadata into
a MOBI periodical-formatted document for the Kindle. It is a wrapper around the
kindlegen program from Amazon that hides the details for templating OPF and NCX
files.

Make sure kindlegen is on the PATH.

Run the program at the root of the file tree:

    kindlerb [filetree dir]

The output will be a mobi document.

The tree structure is 

    opf.yml
    sections/
      000/
        section.yml # contains section title
        001.html # an article
    media/
      001.jpg
      002.jpg
    masthead.gif

kindlerb will extract article titles from the *.html files and create the NCX
from that. (DRY)

_document.yml

    masthead:
      href: masthead.gif
      media: image/gif
    etc.

Need to auto-generate 
  nav-contents.ncx 
  contents.html


Derive 

    opf_manifest_items
    opf_spine_items
    ncx_sections

Pass the whole datastructure to all mustache templates

=end

# extract nav structure

require 'pathname'
require 'yaml'
require 'nokogiri'
require 'mustache'
require 'fileutils'

target_dir = Pathname.new(ARGV.first || '.')

opf_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/opf.mustache"))
ncx_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/ncx.mustache"))
contents_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/contents.mustache"))
section_template = File.read(File.join(File.dirname(__FILE__), '..', "templates/section.mustache"))
masthead_gif = File.join(File.dirname(__FILE__), '..', "templates/masthead.gif")
cover_gif = File.join(File.dirname(__FILE__), '..', "templates/cover-image.gif")

`cp #{masthead_gif} #{target_dir}/masthead.gif` 
`cp #{cover_gif} #{target_dir}/cover-image.gif` 

class String
  def shorten(max)
    if length > max
      Array(self[0,max].split(/\s+/)[0..-2]).join(' ') + '...'
    else
      self
    end
  end
end

Dir.chdir target_dir do
  playorder = 1

  images = []
  manifest_items = []

  document = YAML::load_file("_document.yml")  

  document[:spine_items] = []
  section_html_files = []

  sections = Dir['sections/*'].entries.sort.map.with_index {|section_dir| 
    meta = YAML::load_file((Pathname.new(section_dir) + '_section.yml'))
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
      :title => meta['title'].shorten(40),
      :playorder => (playorder += 1),
      :idref => idref,
      :href => Pathname.new(section_dir) + 'section.html',
      :articles => articles.map {|article_file|
            doc = Nokogiri::HTML(File.read(article_file))
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
              :short_title => title.shorten(40),
              :author => doc.search("html/head/meta[@name=author]").map{|n|n[:name]}.first,
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

  document[:masthead] ||= "masthead.gif"
  document[:first_article] = sections[0][:articles][0]
  document[:sections] = sections


  document[:manifest_items] = manifest_items + images.map.with_index {|img, idx| 
    {
      :href => img[:href],
      :media => img[:mimetype],
      :idref => "img-%03d" % idx
    }
  } 
 
  opf = Mustache.render opf_template, document
  File.open("kindlerb.opf", "w") {|f| f.puts opf}
  puts "Wrote #{target_dir}/kindlerb.opf"

  # NCX
  ncx = Mustache.render ncx_template, document
  File.open("nav-contents.ncx", "w") {|f| f.puts ncx}
  puts "Wrote #{target_dir}/nav-contents.ncx"

  # contents
  contents = Mustache.render contents_template, document
  File.open("contents.html", "w") {|f| f.puts contents}
  puts "Wrote #{target_dir}/contents.html"


  exec "kindlegen -verbose -c2 -o k.mobi kindlerb.opf"
end
