// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../contracts/FlightTicket.sol"; // Adjust path if necessary

contract FlightTicketTest is Test {
    FlightTicket private flightTicket;
    address private owner;

    function setUp() public {
        owner = address(0x123); // You can change this address for testing
        vm.startPrank(owner); // Simulate actions as the owner
        flightTicket = new FlightTicket(owner); // Initialize contract
    }

  // Test 1: Valid flight creation
  function testAddFlightValid() public {
      flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);

      // Correctly access the flight struct from the mapping and check components
      FlightTicket.Flight memory flight = flightTicket.s_flights(0); // Access the flight struct by ID
      assertEq(flight.airportOrigin, "LAX");
      assertEq(flight.airportDestination, "JFK");
      assertEq(flight.aircraftModel, "Boeing 737");
      assertEq(flight.totalSeats, 150);
  }

    // Test 2: Invalid IATA code for origin
    function testAddFlightInvalidOriginIATA() public {
        vm.expectRevert(FlightTicket.FlightTicket_InvalidIATA.selector);
        flightTicket.addFlight("LA", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    // Test 3: Invalid IATA code for destination
    function testAddFlightInvalidDestinationIATA() public {
        vm.expectRevert(FlightTicket.FlightTicket_InvalidIATA.selector);
        flightTicket.addFlight("LAX", "NY", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    // Test 4: Flight departure time is too soon
    function testAddFlightDepartureTimeTooSoon() public {
        vm.expectRevert(FlightTicket.FlightTicket_FlightCannotBeLessThanOneDay.selector);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 6 days), "Boeing 737", 150);
    }

    // Test 5: Empty aircraft model
    function testAddFlightEmptyAircraftModel() public {
        vm.expectRevert(FlightTicket.FlightTicket_AircraftCannotBeEmpty.selector);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "", 150);
    }

    // Test 6: Zero total seats
    function testAddFlightZeroTotalSeats() public {
        vm.expectRevert(FlightTicket.FlightTicket_SeatsMustBeGreaterThanZero.selector);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 0);
    }

    // Test 7: Flight ID increments after each flight
    function testFlightIdIncrements() public {
        uint256 initialFlightId = flightTicket.s_flightId();
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
        assertEq(flightTicket.s_flightId(), initialFlightId + 1);
    }

    // Test 8: Only owner can create a flight
    function testAddFlightOnlyOwner() public {
        vm.stopPrank();
        address nonOwner = address(0x456);
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    // Test 9: Flight created with correct price
    function testAddFlightCorrectPrice() public {
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
        FlightTicket.Flight memory flight = flightTicket.s_flights(0);
        assertEq(flight.price, 0.001 ether);
    }

    // Test 10: Event emitted on flight creation
    function testAddFlightEventEmitted() public {
        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_FlightCreated(0, "LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150, 0.001 ether);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }
}