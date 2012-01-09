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

meta.yml
    masthead:
      href: masthead.gif
      media: image/gif

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

target_dir = Pathname.new(ARGV.first || '.')

opf_template = File.read(File.join(File.dirname(__FILE__) + "/../templates/opf.mustache"))
ncx_template = File.read(File.join(File.dirname(__FILE__) + "/../templates/ncx.mustache"))

Dir.chdir target_dir do
  playorder = 0
  sections = Dir['sections/*'].entries.sort.map.with_index {|section_dir| 
    {
      :meta => YAML::load_file((Pathname.new(section_dir) + '_section.yml')),
      :play_order => (playorder += 1),
      :idref => section_dir.gsub(/\D/, ''),
      :articles => 
        Dir[Pathname.new(section_dir) + '*'].entries.
          select {|x| x !~ /_section.yml/}.sort.
          map.with_index {|article_file|
            doc = Nokogiri::HTML(File.read(article_file))
            {
              :file => article_file,
              :title => doc.search("html/head/title").map(&:inner_text).first,
              :author => doc.search("html/head/meta[@name=author]").map{|n|n[:name]}.first,
              :description => doc.search("html/head/meta[@name=description]").map{|n|n[:content]}.first,
              :playorder => (playorder += 1),
              :idref => article_file.gsub(/\D/, '')
            }
        }
    }
  }
  puts sections.to_yaml
  puts '-' * 80

  # opf file
  document = YAML::load_file("_document.yml")  
  document[:sections] = sections
  document[:manifest_items] = sections.map {|section| 
    section[:articles].map {|article|
      {
        :href => article[:file],
        :media => "application/xhtml+xml",
        :idref => article[:idref]
      }
    }
  }.flatten
  
  document[:spine_items] = sections.map {|section| 
    section[:articles].map {|article|
      {
        :idref => article[:file].gsub(/\D/,'')
      }
    }
  }.flatten
  puts document.inspect

  opf = Mustache.render opf_template, document
  puts opf
  puts '-' * 80

  # NCX
  ncx = Mustache.render ncx_template, document
  puts ncx


end
