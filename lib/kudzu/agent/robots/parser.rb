module Kudzu
  class Agent
    class Robots
      class Parser
        UNMATCH_REGEXP = /^$/

        class << self
          def parse(body)
            txt = Txt.new
            sets = []
            prev_key = nil

            parse_body(body).each do |key, value|
              case key
              when 'user-agent'
                new_set = RuleSet.new(user_agent: ua_regexp(value))
                txt.sets << new_set
                if prev_key == 'user-agent'
                  sets << new_set
                else
                  sets = [new_set]
                end
              when 'allow'
                re = path_regexp(value)
                sets.each { |set| set.rules << Rule.new(path: re, allow: true) }
              when 'disallow'
                re = path_regexp(value)
                sets.each { |set| set.rules << Rule.new(path: re, allow: false) }
              when 'crawl-delay'
                sets.each { |set| set.crawl_delay = value.to_i }
              when 'sitemap'
                txt.sitemaps << value
              end

              prev_key = key
            end

            sort(txt)
          end

          private

          def parse_body(body)
            lines = body.to_s.split(/\r|\n|\r\n/)
            lines.map { |line| parse_line(line) }.compact
          end

          def parse_line(line)
            line.strip!
            if line.empty? || line.start_with?('#')
              nil
            else
              split_line(line)
            end
          end

          def split_line(line)
            key, value = line.split(':', 2)
            key = key.to_s.strip.downcase
            value = value.to_s.sub(/#.*$/, '').strip
            if key.empty? || value.empty?
              nil
            else
              [key, value]
            end
          end

          def ua_regexp(value)
            Regexp.new(Regexp.escape(value).gsub('\*', '.*'))
          rescue RegexpError
            UNMATCH_REGEXP
          end

          def path_regexp(value)
            Regexp.new('^' + Regexp.escape(value).gsub('\*', '.*').gsub('\$', '$'))
          rescue RegexpError
            UNMATCH_REGEXP
          end

          def sort(txt)
            txt.sets.sort_by! { |rule| [-rule.user_agent.to_s.count('*'), rule.user_agent.to_s.length] }.reverse!
            txt.sets.each do |set|
              set.rules.sort_by! { |rule| rule.path.to_s.length }.reverse!
            end
            txt
          end
        end
      end
    end
  end
end
