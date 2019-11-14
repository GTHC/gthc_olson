require "gthc/olson/algorithm"

module GTHC
  module Olson
    extend Algorithm

    def self.driver(peopleList, scheduleGrid)
      # Algorithm
      updatedPeopleList, updatedScheduleGrid = schedule(peopleList, scheduleGrid)
      return updatedPeopleList, updatedScheduleGrid
    end
  end
end
