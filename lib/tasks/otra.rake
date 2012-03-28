# -*- encoding : utf-8 -*-

# OnTheRailsAgain Rake Tasks list

require 'rake/clean'
require 'ruby-debug'
ARTICLE_PATH = File.join(Rails.root, 'app', 'assets', 'articles')

DATE_DELIMITER         = '--date'
TITLE_DELIMITER        = '--title'
INTRODUCTION_DELIMITER = '--introduction'
TAGS_DELIMITER         = '--tags'
CONTENT_DELIMITER      = '--content'
AUTHORS_DELIMITER      = '--authors'
ARTICLE_EXTENSION      = '.article'

namespace :otra do
  
  desc 'Create new articles'
  task :add_new_articles => :environment do 
    Dir.open(ARTICLE_PATH).each do |article_name|
      next if File.extname(article_name) != ARTICLE_EXTENSION # Treat file only .article file

      article_values = parse_article_from_file article_name
      # Create the article only if it doesn't exist yet
      if Article.where(:title => article_values[:title]).empty?
        article = Article.create( :created_at   => article_values[:date],
                                  :title        => article_values[:title],
                                  :introduction => article_values[:introduction],
                                  :authors      => article_values[:authors],
                                  :content      => haml2html(article_values[:content]),
                                  :activated    => true)
        article.tags << article_values[:tags]
      end
    end
  end

  desc 'Generate all articles'
  task :generate_articles => :environment do 
    # First, delete all existing articles
    Article.delete_all
    Dir.open(ARTICLE_PATH).each do |article_name|
      next if File.extname(article_name) != ARTICLE_EXTENSION # Treat file only .article file
      
      article_values = parse_article_from_file article_name
        
      article = Article.create( :created_at   => article_values[:date],
                                :title        => article_values[:title],
                                :introduction => article_values[:introduction],
                                :authors      => article_values[:authors],
                                :content      => haml2html(article_values[:content]),
                                :activated    => true)
      article.tags << article_values[:tags]
    end
  end
  
  # Parse an File article to parse and create a new article 
  # Returns a hash containing all values of an article
  def parse_article_from_file article_file_name
    article_values                = {}
    article_values[:content]      = ''
    article_values[:introduction] = ''
    article_values[:tags]         = []
    article_values[:authors]      = []
    article_values[:title]        = ''
    next_is                       = ''

    puts "Parsing: #{article_file_name}"
    File.open(File.join(ARTICLE_PATH, article_file_name), 'r') do |article_file|      
      article_file.each_line do |line|
        next if line.blank?
        ##### Checking what next line will be
        # Detect date
        if line.include?(DATE_DELIMITER)
          next_is = 'date'
        # Detect introduction
        elsif line.include?(INTRODUCTION_DELIMITER)
          next_is = 'introduction'
        # Detect content
        elsif line.include?(CONTENT_DELIMITER)
          next_is = 'content'
        elsif line.include?(TAGS_DELIMITER)
          next_is = 'tags'
        elsif line.include?(TITLE_DELIMITER)
          next_is = 'title'
        elsif line.include?(AUTHORS_DELIMITER)
          next_is = 'authors'
        else
          case(next_is)
            when 'date'         then article_values[:date]         = Date.parse(line.strip)
            when 'introduction' then article_values[:introduction] << line.strip
            when 'content'      then article_values[:content]      << line
            when 'title'        then article_values[:title]        << line.strip
            when 'authors'      then 
              line.strip.split(',').each do |author|
                author.strip! # Removing eventual spaces at the begining or at the end
                article_values[:authors] << Author.where(:name => author).first
              end
            when 'tags'         then 
              line.strip.split(',').each do |tag_name|
                tag_name.strip! # Removing eventual spaces at the begining or at the end
                # If the tag exists, add it to the list of tags
                if tag = Tag.where(:name => tag_name).first
                  article_values[:tags] << tag
                else
                  article_values[:tags] << Tag.create(:name => tag_name)
                end
              end
          end
        end
      end
    end
    return article_values
  end
  
#   desc 'Update all articles'
#   task :update_article => :environment do
#   end
  def highlight(code, language = :ruby)
    Albino.new(code, language).to_s
  end
  
  def haml2html(content)
    @new_content = Haml::Engine.new(content).to_html

    @new_content.gsub(/<pre.*<\/pre>/) do |matched|
      @language = matched.match(/<pre class='([aA-zZ]*)'>.*pre>/)[1]
      @string   = matched.sub(/<pre class='([aA-zZ]*)'>/, "").sub(/<\/pre>/, "")
      @string   = @string.gsub(/&#x000A;/, "\n").gsub(/&quot;/, '"')
      highlight(@string, @language)
    end.html_safe
  end
end
