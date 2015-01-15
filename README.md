# kindlerb

kindlerb is a Ruby Kindle periodical-format ebook generator. I extracted
this tool from [kindlefeeder.com][kf1]. I also built [Kindlefodder][kf2] on
top of kindlerb.

[kf1]:http://kindlefeeder.com
[kf2]:https://github.com/danchoi/kindlefodder

kindlerb converts a file tree of sections, articles, images, and metadata into
a MOBI periodical-formatted document for the Kindle. It is a wrapper around the
`kindlegen` program from Amazon that hides the details for templating OPF and NCX
files.

## Requirements

* Ruby 1.9.x. 
* Make sure kindlegen is on your PATH.

You can get kindlegen [here][kindlegen].

[kindlegen]:http://www.amazon.com/gp/feature.html?docId=1000234621

## Install

Add `gem 'kindlerb'` to your Gemfile then run `bundle install`
    
OR run:

    gem install kindlerb

## How to use it 

Require kindlerb in your project.

    require 'kindlerb'

### Kindlerb.run(target_dir, verbose, compression_method)

Only the first argument is mandatory, everything else will use default values if no arguments are provided.

**target_dir** = Put the directory that contains your ebook files

**verbose** = true or false. Default is false.

**compression_method** = 'c0' (no compression) OR 'c1' (standard DOC compression) OR 'c2' (Kindle huffdic compression). Default is 'c2'.

The output will be a mobi document.

**target_dir** should include the below files and structure: 

    _document.yml
    sections/
      000/
        _section.txt # contains section title
        000.html # an article
        001.html 
      001/
        _section.txt 
        000.html
        001.html 
        002.html

kindlerb will extract article titles from the `<title>` (in `<head>`) tag in
the *.html files .

The _document.yml is a YAML document. It should look like something like this:

    --- 
    doc_uuid: kindlerb.21395-2011-12-19
    title: my-ebook
    author: my-ebook
    publisher: me
    subject: News
    date: "2011-12-19"
    masthead: /home/choi/Desktop/masthead.gif
    cover: /home/choi/Desktop/cover.gif
    mobi_outfile: my-ebook.mobi

kindlerb uses the the file tree and _document.yml to construct these additional
resource required by Amazon's `kindlegen` program:

* nav-contents.ncx 
* contents.html
* kindlerb.opf

After that, kindlerb will exec the kindlegen program to generate your mobi
document.  The filename the output document is specified by the 'mobi_outfile'
value in _document.yml.

### Kindlerb.executable
Will return the full path to the Kindlegen executable file.

### Kindlerb.download
This is automatically called when you first install the gem. It downloads the appropriate Kindlegen version for the host OS.

## Images

kindlerb will incorporate images into the generated ebook by parsing all the
`src` attributes of all the `<img>` tags in your *.html files.

The `src` attributes must point to image files on the local filesystem. If the
paths are relative, they should be relative to the target file tree root. 


## Encoding

Make sure all your textual source files are encoded in UTF-8.


## Author 

**Daniel Choi**
* email: dhchoi@gmail.com
* github: [danchoi][github]
* twitter: @danchoi
[github]:http://github.com/danchoi

**Emir Aydin**
* email: emir@emiraydin.com
* github: [emiraydin][github]
* twitter: @emiraydin
[github]:http://github.com/emiraydin


Indebted to [mhl][mhl] for writing the
[guardian-for-kindle][guardian-for-kindle] MOBI generator in Python. kindlerb
ported a bunch of ideas from that project over to Ruby.

[mhl]:https://github.com/mhl
[guardian-for-kindle]:https://github.com/mhl/guardian-for-kindle