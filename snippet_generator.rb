require 'open-uri'
require 'nokogiri'
require 'erb'
require 'fileutils'

module FontAwesome
  URL = 'http://fortawesome.github.io/Font-Awesome/icons/'

  module Atom
    OUTPUT_DIR = 'snippets'
    OUTPUT_SAMPLE_DIR = 'samples'

    class Generator
      def initialize(klasses, version)
        @klasses = klasses
        @version = version
      end

      def bulk_output
        FileUtils.mkdir_p(OUTPUT_SAMPLE_DIR)
        sample_html = apply_sample_html
        output_sample_html(sample_html)

        FileUtils.mkdir_p(OUTPUT_DIR)
        cson_src = apply_snippet
        output_snippets(cson_src)
      end

      def apply_sample_html
        samples = @klasses.map { |klass|
          format("<tr><td><i class='fa %s' style='font-size:3em;'></i></td><td>%s</td></tr>", klass, klass)
        }.join("\n")

        template =<<-EOS
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Font Awesome Samples</title>
  <link href='http://fonts.googleapis.com/css?family=Crete+Round' rel='stylesheet' type='text/css'>
  <link href="http://maxcdn.bootstrapcdn.com/font-awesome/#{@version}/css/font-awesome.min.css" rel="stylesheet">
  <style type="text/css">
  body {
    font-family: Crete Round, Arial, serif;
  }
  h1  {
    width: 400px;
    margin: 0 auto;
  }
  table {
    width: 400px;
    margin: 0 auto;
  }
  td {
    text-align:left;
  }
  </style>
</head>
<body>
  <h1>Font Awesome Samples</h1>
  <hr>
  <table>
  <%=samples%>
  </table>
</body>
</html>
        EOS
        ERB.new(template).result(binding)
      end

      def output_sample_html(sample_html)
        path = "./#{OUTPUT_SAMPLE_DIR}/fontawesome_samples.html"
        File.open(path, "w:utf-8") { |e|e.puts(sample_html) }
      end

      def apply_snippet
        header =<<-EOS
".text.html, .source.gfm, .text.php":
\t"Font Awesome Includes":
\t\t"prefix":"font-awesome-import"
\t\t"body":'<link href="//maxcdn.bootstrapcdn.com/font-awesome/#{@version}/css/font-awesome.min.css" rel="stylesheet">'
        EOS

        body = @klasses.map{|klass|
          <<-EOS
\t"#{klass}":
\t\t"prefix":"#{klass}"
\t\t"body":'<i class="fa #{klass}"></i>'
          EOS
        }.join
        header + body
      end

      def output_snippets(snippet)
        File.open("./#{OUTPUT_DIR}/font-awesome.cson", "w:utf-8") do |e|
          e.puts(snippet)
        end
      end
    end
  end
end

charset = nil
html = open(FontAwesome::URL) do |f|
  charset = f.charset
  f.read
end

doc = Nokogiri::HTML.parse(html, nil, charset)
version = doc.xpath('//div[contains(@class,"jumbotron")]/div/p').first.text.gsub(/.+ (\d+\.\d+\.\d)/, '\1')
klasses = doc.xpath('//i[contains(@class,"fa")]')
   .map { |e|e.attributes.first.last.value }
   .map { |e|e.split(' ') }
   .select { |e|e.size === 2 }
   .map { |e|e[1] }
   .to_a
   .uniq
   .sort

FontAwesome::Atom::Generator.new(klasses, version).bulk_output
