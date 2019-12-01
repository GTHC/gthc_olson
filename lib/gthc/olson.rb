require "gthc/olson/algorithm"
require "gthc/olson/person"
require "gthc/olson/slot"

module GTHC
  module Olson
    extend Algorithm

    def self.driver(peopleList, scheduleGrid)
      # Algorithm
      schedule(peopleList, scheduleGrid)  
    end

    def self.Person
      Person
    end

    def self.Slot
      Slot
    end
  end
end
