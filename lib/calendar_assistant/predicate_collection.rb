class CalendarAssistant
  module PredicateCollection
    def self.build(must_be, must_not_be)
      predicates = {}
      Array(must_be).each do |predicate|
        predicates[predicate_symbol(predicate)] = true
      end

      Array(must_not_be).each do |predicate|
        predicates[predicate_symbol(predicate)] = false
      end

      predicates
    end

    def self.predicate_symbol(str)
      str.to_s.gsub(/(.*[^?])$/, "\\1?").to_sym
    end
  end
end
