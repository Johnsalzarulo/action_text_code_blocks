class Article < ApplicationRecord
    has_rich_text :body

    def formatted_body
      Richtext::CodeBlocks::HtmlService.render(self.body.to_s).html_safe
    end
    
end
