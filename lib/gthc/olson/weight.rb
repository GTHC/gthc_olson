require "gthc/olson/helpers"

module Weight
  include Helpers

  # Weight Reset - set all weights to 1.
  def self.weightReset(slots)
    slots.each do | currentSlot |
      currentSlot.weight = 1;
    end
    slots
  end

  # Weight Balance - prioritize people with fewer scheduled shifts
  def self.weightBalance(people, slots)

    slots.each do | currentSlot |

      # Establish variables.
      currentPersonID = currentSlot.personID
      dayScheduled = people[currentPersonID].dayScheduled
      nightScheduled = people[currentPersonID].nightScheduled
      night = currentSlot.isNight;

      nightMulti = 0;
      dayMulti = 0;

      # Set multipliers.
      if nightScheduled != 0
        nightMulti = 1.0 / nightScheduled
      else
        nightMulti = 1.5
      end

      if dayScheduled != 0
        dayMulti = (1.0/(dayScheduled+nightScheduled*4*2))
      else
        dayMulti = 1.5
      end

      #Adjust weights with multipliers.
      if night
        currentSlot.weight = currentSlot.weight * nightMulti
      else
        currentSlot.weight = currentSlot.weight * dayMulti
      end

    end
    return people, slots
  end

  def self.gridLimits(row, rowLength)
    return row - 1 < 0,
           row + 1 > rowLength - 1
  end

  # Weight Contiguous - prioritize people to stay in the tent more time at once.
  def self.weightContiguous(slots, scheduleGrid, graveyard)

    i = 0
    while i < slots.length
      # Establish Variables
      currentRow = slots[i].row
      currentCol = slots[i].col

      aboveRow = currentRow-1
      belowRow = currentRow+1

      # grab all slots under the same col as the inspected slot in order
      # to get the slots above and below
      allSlots = scheduleGrid[currentCol]
      slotsLength = allSlots.length

      # find what to skip
      skipAboveRow, skipBelowRow = gridLimits(currentRow, slotsLength)

      currentIsNight = slots[i].isNight
      aboveIsNight = !skipAboveRow && allSlots[aboveRow].isNight
      belowIsNight = !skipBelowRow && allSlots[belowRow].isNight

      aboveTent = !skipAboveRow && allSlots[aboveRow].status == "Scheduled"
      belowTent = !skipBelowRow && allSlots[belowRow].status == "Scheduled"
      aboveSome = !skipAboveRow && allSlots[aboveRow].status == "Somewhat"
      belowSome = !skipBelowRow && allSlots[belowRow].status == "Somewhat"
      aboveFree = !skipAboveRow && allSlots[aboveRow].status == "Available"
      belowFree = !skipBelowRow && allSlots[belowRow].status == "Available"

      multi = 1

      # Both are scheduled.
      if aboveTent && belowTent
        multi = 100
      end

      # Both are not free
      if !belowTent && !belowFree && !aboveSome && !belowSome && !aboveTent && !aboveFree
        if slots[i].weight > 0
          multi = -1
        end
      end

      # Above is scheduled, below is free.
      if aboveTent && !belowTent && belowFree
        multi = 3.25
      end

      # Below is scheduled, above is free.
      if belowTent && !aboveTent && aboveFree
        multi = 3.25
      end

      # Above is scheduled, below is not free.
      if aboveTent && !belowTent && !belowFree
        multi = 3
      end

      # Below is scheduled, above is not free.
      if belowTent && !aboveTent && !aboveFree
        multi = 3
      end

      # Both are free
      if belowFree && aboveFree
        multi = 2.75
      end

      # Above is free, below is not free
      if aboveFree && !belowTent && !belowFree
        multi = 1
      end

      # Below is free, above is not free
      if(belowFree && !aboveTent && !aboveFree)
        multi = 1
      end

      # Night Multi
      if aboveIsNight || belowIsNight || currentIsNight
        multi *= 1.25
      end

      # Occurance of Somewhat Available
      if aboveSome || belowSome
        multi *= 0.5
      end

      slots[i].weight = slots[i].weight*multi
      i += 1

    end

    return slots, scheduleGrid, graveyard
  end

  # Weight Tough Time - prioritize time slots with few people available. */
  def self.weightToughTime(slots, scheduleLength)

    # Set up counterArray (Rows that are filled).
    counterArray = Array.new(scheduleLength + 1, 0)

    # Fill counterArray.
    slots.each do | currentSlot |
      currentRow = currentSlot.row
      counterArray[currentRow] = counterArray[currentRow] + 1
    end

    # Update Weights.
    slots.each do | currentSlot |
      currentRow = currentSlot.row
      currentPhase = currentSlot.phase
      nightBoolean = currentSlot.isNight
      peopleNeeded = Helpers.calculatePeopleNeeded(nightBoolean, currentPhase)
      numFreePeople = counterArray[currentRow]
      currentSlot.weight = currentSlot.weight*(12/numFreePeople)*peopleNeeded
    end

    return slots
  end

  # Update people, spreadsheet, and remove slots.
  def self.weightPick(people, slots, graveyard, scheduleGrid)

    # Remove winner from list.
    winner = slots.shift;

    # Update person information.
    currentPersonID = winner.personID;
    currentTime = winner.isNight;

    if currentTime
      people[currentPersonID].nightScheduled += 1
      people[currentPersonID].nightFree -= 1
     else
      people[currentPersonID].dayScheduled += 1
      people[currentPersonID].dayFree -= 1
    end

    # Establish Variables
    currentRow = winner.row
    currentCol = winner.col
    tentCounter = 0

    # Update Data
    scheduleGrid[currentCol][currentRow].status = "Scheduled";

    # Count number of scheduled tenters during winner slot.
    i = 0
    while i < scheduleGrid.length
      if scheduleGrid[i][currentRow].status == "Scheduled"
        tentCounter = tentCounter + 1
      end
      i += 1
    end

    # Determine how many people are needed.
    peopleNeeded = Helpers.calculatePeopleNeeded(currentTime, winner.phase)

    # Update Slots and Graveyard
    if tentCounter >= peopleNeeded
      graveyard[currentRow] = 1
      j = 0
      tempSlots = []
      while j < slots.length
        tempRow = slots[j].row
        if tempRow != currentRow
          tempSlots.push slots[j]
        end
        j += 1
      end
      slots = tempSlots
    end

    return people, slots, graveyard, scheduleGrid
  end
end
