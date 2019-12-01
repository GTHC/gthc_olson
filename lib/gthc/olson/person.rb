class Person
    attr_accessor :id,
                  :name,
                  :dayFree, :nightFree,
                  :dayScheduled, :nightScheduled
  
    def initialize(id, name, dayFree, nightFree, dayScheduled, nightScheduled)
      @id = id
      @name = name
      @dayFree = dayFree
      @dayScheduled = dayScheduled
      @nightFree = nightFree
      @nightScheduled = nightScheduled
      # @maxDayHours = maxDayHours
      # @idealDayHours = idealDayHours
    end
end