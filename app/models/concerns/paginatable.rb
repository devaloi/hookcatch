module Paginatable
  extend ActiveSupport::Concern

  PER_PAGE = 25

  included do
    scope :page, ->(page_num) {
      page_num = [ (page_num.to_i), 1 ].max
      limit(PER_PAGE).offset((page_num - 1) * PER_PAGE)
    }
  end

  class_methods do
    def current_page
      1
    end

    def total_count
      count
    end
  end
end
