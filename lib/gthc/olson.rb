require "olson/algorithm"

class GTHC::Olson
  include Algorithm
  # Main Driver
  def self.driver(peopleList, scheduleGrid)

    # Algorithm
    updatedPeopleList, updatedScheduleGrid = Algorithm.schedule(peopleList, scheduleGrid)

    return updatedPeopleList, updatedScheduleGrid

  end
end
