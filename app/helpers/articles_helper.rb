module ArticlesHelper
  
  def join_tags(article)
    content_tag(:ul, article.tags(true).collect { |tag| content_tag(:li, link_to(tag.name, articles_path(:tag => tag.name), :rel => 'tag')) }.join(' ').html_safe, :class => 'tags_list')
  end

  # Join all authors of an article with the keyword 'et'
  def join_authors(article)
    article.authors.collect{ |author| link_to author.name, articles_path(:author => author.name) }.join(' et ').html_safe
  end

  # Join all authors of an article with the keyword 'et' without link
  def join_authors_without_link(article)
    article.authors.collect{ |author| author.name }.join(' et ').html_safe
  end

end
