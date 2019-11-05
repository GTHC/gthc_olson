require "./helpers"

module Weight
  include Helpers

  # Weight Reset - set all weights to 1.
  def weightReset(slots)
    slots.each do | currentSlot |
      currentSlot.weight = 1;
    end
    slots
  end

  # Weight Balance - prioritize people with fewer scheduled shifts
  def weightBalance(people, slots)

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

  def gridLimits(row, col, rowLength, colLength)
    return row - 1 < 0,
           col - 1 < 0,
           row + 1 > rowLength - 1,
           col + 1 > colLength - 1
  end

  # Weight Contiguous - prioritize people to stay in the tent more time at once.
  def weightContiguous(people, slots, scheduleGrid, graveyard)

    i = 0
    while i < slots.length
      # puts i
      # Establish Variables
      currentRow = slots[i].row
      currentCol = slots[i].col
      night = slots[i].isNight

      aboveRow = currentRow-1
      belowRow = currentRow+1
      aboveCol = currentCol-1
      belowCol = currentCol+1

      # find what to skip
      skipAboveRow, skipAboveCol, skipBelowRow, skipBelowCol = gridLimits(
                                                                          currentRow,
                                                                          currentCol,
                                                                          scheduleGrid[belowCol].length,
                                                                          scheduleGrid.length
                                                                        )

      currentIsNight = slots[i].isNight
      aboveIsNight = !skipAboveCol && !skipAboveRow && scheduleGrid[aboveCol][aboveRow].isNight
      belowIsNight = !skipBelowCol && !skipBelowRow && scheduleGrid[belowCol][belowRow].isNight

      aboveTent = !skipAboveCol && !skipAboveRow && scheduleGrid[aboveCol][aboveRow].status == "Scheduled"
      belowTent = !skipBelowCol && !skipBelowRow && scheduleGrid[belowCol][belowRow].status == "Scheduled"
      aboveFree = !skipAboveCol && !skipAboveRow && scheduleGrid[aboveCol][aboveRow].status == "Available"
      belowFree = !skipBelowCol && !skipBelowRow && scheduleGrid[belowCol][belowRow].status == "Available"

      multi = 1

      # Determine tent, available, and not available for above
      if graveyard[aboveRow] == 1 && aboveFree
        aboveFree = false
      end

      # Determine tent, available, and not available for below
      if graveyard[belowRow] == 1 && belowFree
        belowFree = false
      end

      # Both are scheduled.
      if aboveTent && belowTent
        multi = 100
      end

      # Both are not free
      if !belowTent && !belowFree && !aboveTent && !aboveFree
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
        multi = multi*1.25
      end

      slots[i].weight = slots[i].weight*multi
      i += 1

    end

    return people, slots, scheduleGrid, graveyard
  end

  # Weight Tough Time - prioritize time slots with few people available. */
  def weightToughTime(people, slots, length)

    # Set up counterArray (Rows that are filled).
    counterArray = Array.new(length+1, 0)

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

    return people, slots
  end

  # Update people, spreadsheet, and remove slots.
  def weightPick(people, slots, results, graveyard, scheduleGrid)

    # Remove winner from list.
    winner = slots.shift;
    results.push(winner);

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
    currentPhase = winner.phase
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
      tempSlot = slots.dup # deepcopy slots
      while j < slots.length
        tempRow = slots[j].row
        tempID = slots[j].personID
        tempNight = slots[j].isNight
        if tempRow == currentRow
          if tempNight
            people[tempID].nightFree -= 1
          else
            people[tempID].dayFree -= 1
          end
          tempSlot.delete(j);
        end
        j += 1
      end
      slot = tempSlot
    end

    return people, slots, results, graveyard, scheduleGrid
  end
end
