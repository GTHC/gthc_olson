require "./olson/algorithm"

class GTHC::Olson
  extend Algorithm

  def self.driver(peopleList, scheduleGrid)
    # Algorithm
    updatedPeopleList, updatedScheduleGrid = schedule(peopleList, scheduleGrid)
    return updatedPeopleList, updatedScheduleGrid
  end

end
