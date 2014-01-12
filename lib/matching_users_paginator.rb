class MatchingUsersPaginator

  def self.find(options = {})
    mup = MatchingUsersPaginated.new options
    find_options = {
      :conditions => mup.conditions,
      :offset => (mup.page - 1) * mup.results_per_page,
      :limit => mup.results_per_page
    }
    find_options[:origin] = mup.origin if mup.origin.present?
    find_options[:within] = mup.within if mup.within.present?
    find_options[:order] = mup.order if mup.order.present?
    
    mup.total_results_count = User.count(:all, find_options.except(:offset, :limit, :order))
    mup.current_page_results = User.find :all, find_options
    mup
  end

end

class MatchingUsersPaginated

  attr_accessor :results_per_page, :page, :conditions, :current_page_results,
                :total_results_count, :origin, :within, :order
  
  def initialize(options = {})
    options[:conditions] ||= {}
    options[:results_per_page] ||= DEFAULT_SEARCH_RESULTS_PER_PAGE
    options [:page] ||= 1

    @results_per_page = options[:results_per_page]
    @page = options[:page].to_i
    @conditions = options[:conditions]
    @origin = options[:origin]
    @within = options[:within]
    @order = options[:order]
  end
  
  def show_page_links?
    total_page_count >= 3
  end
  
  def show_first_link?
    in_middle?
  end
  
  def show_last_link?
    in_middle?
  end
  
  def has_results?
    total_results_count > 0
  end
  
  def in_middle?
    large_result_set? && !at_beginning? && !at_end?
  end
  
  def large_result_set?
    total_page_count > 10
  end
  
  def at_beginning?
    large_result_set? and (page <= 8)
  end
  
  def at_end?
    large_result_set? && (page >= total_page_count - 7)
  end
  
  def total_page_count
    return 1 if total_results_count == 0

    total_pages = total_results_count / results_per_page
    total_pages += 1 if (total_results_count % results_per_page) > 0
    total_pages
  end
  
  def page_numbers_to_link
    return (1..total_page_count).to_a if !large_result_set?
    
    if at_beginning?
      return (1..8).to_a + [nil] + [total_page_count - 1, total_page_count]
    elsif at_end?
      return [1, 2, nil] + ((total_page_count - 7)..total_page_count).to_a
    else
      return ((page - 4)..(page - 1)).to_a + [nil] + ((page + 1)..(page + 5)).to_a
    end
  end
  
  def has_next_page?
    total_page_count > 1 && page < total_page_count
  end
  
  def has_prev_page?
    total_page_count > 1 && page > 1
  end

end