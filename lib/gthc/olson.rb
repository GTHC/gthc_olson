require "gthc/olson/algorithm"
require "gthc/olson/person"
# require "gthc/olson/slot"

module GTHC
  module Olson
    extend Algorithm
    include Person

    def self.driver(peopleList, scheduleGrid)
      # Algorithm
      schedule(peopleList, scheduleGrid)  
    end

    def self.Person(id, name, dayFree, nightFree, dayScheduled, nightScheduled)
      Person.new(id, name, dayFree, nightFree, dayScheduled, nightScheduled)
    end

    # def self.Slot(personID, startDate, endDate, phase, isNight, status, row, col, weight=1)
    #   Slot.new(personID, startDate, endDate, phase, isNight, status, row, col, weight)
    # end
  end
end
