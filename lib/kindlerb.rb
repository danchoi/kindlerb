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

kindlerb will extract article titles from the *.html files and create the NCX
from that. (DRY)

=end

# extract nav structure

require 'pathname'
require 'yaml'
require 'nokogiri'

target_dir = Pathname.new(ARGV.first || '.')

Dir.chdir target_dir do
  Dir['sections/*'].entries.sort.map {|section_dir| 
    puts section_dir
    section = {
      :section_meta => YAML::load_file((Pathname.new(section_dir) + '_section.yml')),
      :articles => 
        Dir[Pathname.new(section_dir) + '*'].entries.select {|x| x !~ /_section.yml/}.sort.map {|article_file|
          doc = Nokogiri::HTML(File.read(article_file))
          {
            :file => article_file,
            :title => doc.search("html/head/title").map(&:inner_text).first,
            :author => doc.search("html/head/meta[@name=author]").map{|n|n[:name]}.first,
            :description => doc.search("html/head/meta[@name=description]").map{|n|n[:content]}.first
          }
        }
    }
    puts section.to_yaml
  }

end
