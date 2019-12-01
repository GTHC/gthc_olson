require "gthc/olson/algorithm"

module GTHC
  module Olson
    extend Algorithm

    def self.driver(peopleList, scheduleGrid)
      # Algorithm
      schedule(peopleList, scheduleGrid)  
    end
  end
end
