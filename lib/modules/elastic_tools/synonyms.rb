module ElasticTools
  module Synonyms
    class Dictionary
      attr_reader :calibers, :manufacturers

      def initialize
        @calibers = ThreadSafe::Cache.new
        @calibers['handgun'] = ElasticTools::Synonyms.category_keywords("handgun calibers")
        @calibers['rimfire'] = ElasticTools::Synonyms.category_keywords("rimfire calibers")
        @calibers['shotgun'] = ElasticTools::Synonyms.category_keywords("shotgun calibers")
        @calibers['rifle'] = ElasticTools::Synonyms.category_keywords("rifle calibers")
        @manufacturers = ElasticTools::Synonyms.category_keywords("manufacturers")
      end

      def all_keywords
        manufacturers + handgun_calibers + rimfire_calibers + shotgun_calibers + rifle_calibers
      end
    end

    class Synonyms
      attr_reader :caliber_synonym_lines, :general_synonym_lines, :manufacturer_synonym_lines, :all_synonym_lines

      def initialize
        @general_synonym_lines = File.readlines("#{Rails.root}/lib/elasticsearch/synonyms.txt").map(&:strip).reject(&:blank?)
        @caliber_synonym_lines = File.readlines("#{Rails.root}/lib/elasticsearch/caliber_synonyms.txt").map(&:strip).reject(&:blank?)
        @manufacturer_synonym_lines = File.readlines("#{Rails.root}/lib/elasticsearch/manufacturer_synonyms.txt").map(&:strip).reject(&:blank?)
        @all_synonym_lines = @general_synonym_lines + @caliber_synonym_lines + @manufacturer_synonym_lines
      end

      def explicit_mappings(opt=nil)
        lines = case opt
                when :caliber
                  caliber_synonym_lines
                when :manufacturer
                  manufacturer_synonym_lines
                else
                  all_synonym_lines.map { |l| l.gsub("_", " ") }
                end

        lines.reject do |line|
          (line[0] == "#") || !line["=>"]
        end
      end

      def equivalent_synonyms
        @equivalent_synonyms ||= explicit_mappings.map { |line| line.downcase.sub(" => ", ",").gsub("_", " ") }
      end

      def category_keywords(category)
        start = all_synonym_lines.index("# #{category} - begin") + 1
        finish = all_synonym_lines.index("# #{category} - end") - 1
        lines = all_synonym_lines[start..finish]
        lines.reject { |line| line["#"] || line.strip.empty?}.map do |line|
          line["=>"] ? line.split("=>").last.strip : line
        end
      end
    end

    class << self
      delegate :explicit_mappings, :equivalent_synonyms, :category_keywords, to: :synonyms
      delegate :manufacturers, :calibers, to: :dictionary

      def synonyms
        @synonyms ||= Synonyms.new
      end

      def dictionary
        @dictionary ||= Dictionary.new
      end
    end
  end
end
