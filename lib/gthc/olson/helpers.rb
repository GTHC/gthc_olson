module Helpers
  def self.calculatePeopleNeeded(nightBoolean, phase)
    if phase == "Black"
      if nightBoolean
        return 10
      else
        return 2
      end
    end
    if phase == "Blue"
      if nightBoolean
        return 6
      else
        return 1
      end
    end
    if phase == "White"
      if nightBoolean
        return 2
      else
        return 1
      end
    end
  end

end
