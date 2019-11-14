require "gthc/olson/helpers"
require "gthc/olson/weight"

module GTHC::Olson
  module Algorithm

    include Helpers
    extend Weight

    # Central document for creating schedule.
    def self.schedule(people, scheduleGrid)

      # Create results and scheduled rows "graveyard"
      results = Array.new

      # Remove all availability slots that are already filled in the schedule.
      slots, graveyard, people, scheduleGrid = removeFilledSlots(people, scheduleGrid)

      count = 0

      # Remove all availability slots that are already filled in the schedule.
      while slots.length > 0
        count += 1

        # Weight Reset - set all weights to 1.
        slots = weightReset(slots)

        # Weight Balance - prioritize people with fewer scheduled shifts.
        people, slots = weightBalance(people, slots)

        # Weight Contiguous - prioritize people to stay in the tent more time at once.
        people, slots, scheduleGrid, graveyard = weightContiguous(people, slots, scheduleGrid, graveyard)

        # Weight Tough Time - prioritize time slots with few people available.
        people, slots = weightToughTime(people, slots, scheduleGrid[0].length)

        # Sort by Weights
        slots.sort_by { |a| -a.weight }

        # Update people, spreadsheet, and remove slots.
        people, slots, results, graveyard, scheduleGrid = weightPick(people, slots, results, graveyard, scheduleGrid)

      end

      return people, scheduleGrid

    end


    # Remove all availability slots that are already filled in the schedule.
    def self.removeFilledSlots(people, scheduleGrid)

      # Reset Slots Array.
      slots = Array.new
      # Set up graveyard (Rows that are completely scheduled will go here).
      graveyard = Array.new(scheduleGrid[0].length, 0)
      # Set up counterArray (Going to count how scheduled a row is).
      counterArray = Array.new(scheduleGrid[0].length, 0)

      # Count number of scheduled tenters during a specific time.
      scheduleGrid.each do | currentPerson |
        counter = 0
        while counter < currentPerson.length
          if currentPerson[counter].status == "Scheduled"
            counterArray[counter] = counterArray[counter] + 1
          end
          counter = counter + 1
        end
      end

      # Iterate through every slot.
      i = 0
      while i < scheduleGrid.length

        currentPerson = scheduleGrid[i]
        counter = 0

        while counter < scheduleGrid[i].length

          # Determine how many people are needed.
          nightBoolean = currentPerson[counter].isNight
          phase = currentPerson[counter].phase
          peopleNeeded = Helpers.calculatePeopleNeeded(nightBoolean, phase)
          numPeople = counterArray[counter]

          # Only add in slot if necessary.
          if numPeople < peopleNeeded && currentPerson[counter].status == "Available"
            slots.push(currentPerson[counter])
          end

          # Update graveyard
          if numPeople >= peopleNeeded
            graveyard[counter] = 1
          end

          # Update person freedom
          if numPeople >= peopleNeeded  && currentPerson[counter].status == "Available"
            if isNight
              people[i].nightFree -= 1
            else
              people[i].dayFree -= 1
            end
          end

          counter = counter + 1

        end

        i = i + 1

      end

      return slots, graveyard, people, scheduleGrid

    end

  end

end
