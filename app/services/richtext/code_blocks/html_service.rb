class Richtext::CodeBlocks::HtmlService
  ALLOWED_HTML_TAGS = ["table", "tr", "td", "th", "col", "pre", "p", "h1", "h2", "h3", "summary", "details", "row", "code"]
  ALLOWED_HTML_ATTRIBUTES = []

  def self.validate(html)
    errors = []
    html = Nokogiri::HTML::DocumentFragment.parse(html)
    html.search("pre").each do |pre_tag|
      pre_tag_html, pre_tag_errors = self.ensure_well_formed_markup(pre_tag.text)
      errors.push(pre_tag_errors) unless pre_tag_errors.empty?
      inner_html = self.extract_inner_html_from_pre_tag(pre_tag_html)
      inner_html = self.remove_not_allowed_tags_and_attributes(inner_html)
      pre_tag.children.first.replace(Nokogiri::XML::Text.new(
        inner_html,
        pre_tag
      ))
    end
    html = ActionText::Fragment.new(html)
    [html.to_html, errors.flatten.uniq]
  end

  def self.render(rich_text)
    html = Nokogiri::HTML::DocumentFragment.parse(rich_text)
    html.search("pre").each do |pre_tag|
      inner_html = Nokogiri::HTML::DocumentFragment.parse(pre_tag.text)
      inner_html = add_styles_to_tables(inner_html)
      advanced_code_block = "<div class='advanced-code-block'>#{inner_html.to_html}</div>"
      pre_tag.replace(advanced_code_block)
    end
    html.to_html
  end

  private

  def self.ensure_well_formed_markup(html)
    parsed = Nokogiri::XML("<pre>#{html}</pre>")
    [parsed, parsed.errors]
  end

  def self.remove_not_allowed_tags_and_attributes(block, whitelist= ALLOWED_HTML_TAGS)
    block.children.each do |b|
      b.xpath('//@*').remove
      next if b.text?
      self.remove_not_allowed_tags_and_attributes(b)
      unless whitelist.include?(b.name)
        b.remove
      end
    end
    block.to_html
  end

  def self.add_styles_to_tables(html)
    html.search("table").each do |table|
      table["class"] = "table"
      table.wrap("<div class='table-responsive'></div>")
    end
    html
  end

  def self.extract_inner_html_from_pre_tag(html)
    Nokogiri::XML(html.at("pre").inner_html)
  end

  def self.error_messages(errors)
    readable_message = ->(e) { e.message.split(":")[3].strip rescue "" }
    errors.map {|e| readable_message.call(e) }.uniq.join(", ")
  end

end
