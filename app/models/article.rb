class Article < ApplicationRecord
    has_rich_text :body
    before_save :validate_code_blocks

    def formatted_body
      Richtext::CodeBlocks::HtmlService.render(self.body.to_s).html_safe
    end

    def validate_code_blocks
      return true unless self.body.present?
      html, errors = Richtext::CodeBlocks::HtmlService.validate(self.body.body.to_html)
      if errors.any?
        self.errors.add(:base, "Advance Code Blocks: #{Richtext::CodeBlocks::HtmlService.error_messages(errors)}")
        throw(:abort)
      else
        self.body = html
      end
    end
end
