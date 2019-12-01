# Slots objects make up the ScheduleGrid input.

class Slot
    attr_accessor :personID, :ids,
                  :startDate, :endDate,
                  :phase,
                  :isNight,
                  :status,
                  :row, :col,
                  :weight
  
    def initialize(personID, startDate, endDate, phase, isNight, status, row, col, weight=1)
      @personID = personID
      @startDate = startDate
      @endDate = endDate
      @phase = phase
      @isNight = isNight
      @status = status
      @row = row
      @col = col
      @weight = 1
      @ids = nil
    end
  
    def to_hash
      hash = {}
      instance_variables.each { |var| hash[var.to_s.delete('@')] = instance_variable_get(var) }
      hash
    end
  
    def self.attr_accessor(*vars)
      @attributes ||= []
      @attributes.concat vars
      super(*vars)
    end
  
    def self.attributes
      @attributes
    end
  
    def attributes
      self.class.attributes
    end
end