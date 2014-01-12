module UserHelper

  def age_select_options(options = {})
    options[:selected] = 18 if options[:selected].blank?
    (18..99).to_a.map { |x| "<option #{'selected' if options[:selected] == x}>#{x}</option>" }.join
  end
  
end
