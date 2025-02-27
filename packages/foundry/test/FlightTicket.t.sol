// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../contracts/FlightTicket.sol"; // Adjust path if necessary

contract FlightTicketTest is Test {
    FlightTicket private flightTicket;
    address private owner = address(0x123);
    address public passenger = address(2);
    uint256 flightId = 0;

    function setUp() public {
        vm.startPrank(owner); // Simulate actions as the owner
        flightTicket = new FlightTicket(owner); // Initialize contract
        vm.deal(passenger, 10 ether);
    }

    // Test 1: Valid flight creation
    function testAddFlightValid() public {
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
        flightTicket.addFlight("SFO", "ORD", uint48(block.timestamp + 10 days), "Airbus A320", 200);

        FlightTicket.Flight memory flight = flightTicket.getFlight(0);
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
        FlightTicket.Flight memory flight = flightTicket.getFlight(0);
        assertEq(flight.price, 0.001 ether);
    }

    // Test 10: Event emitted on flight creation
    function testAddFlightEventEmitted() public {
        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_FlightCreated(0, "LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150, 0.001 ether);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    function testGetFlightInvalid() public {
        vm.expectRevert();
        flightTicket.getFlight(100); // Non-existent flight
    }

    // Test getFlightURI function
    function testGetFlightURIValid() public {
        string memory uri = flightTicket.getFlightURI(0);
        assert(bytes(uri).length > 0);
        assertTrue(bytes(uri).length > 50); // Basic check to ensure it's not empty
    }

    function testGetFlightURIInvalid() public {
        vm.expectRevert();
        flightTicket.getFlightURI(100); // Non-existent flight
    }

    // Test getSeatStatus function
    function testGetSeatStatusValid() public {
        uint256 availableSeats = flightTicket.getSeatStatus(0);
        assertEq(availableSeats, 150); // No seats booked yet
    }

    function testGetSeatStatusInvalid() public {
        vm.expectRevert(FlightTicket.FlightTicket_FlightDoesNotExist.selector);
        flightTicket.getSeatStatus(100); // Non-existent flight
    }

    // Additional test cases
    function testFlightSeatReduction() public {
        vm.prank(owner);
        flightTicket.bookSeat{value: 0.001 ether}(0); // Simulating a ticket purchase
        uint256 availableSeats = flightTicket.getSeatStatus(0);
        assertEq(availableSeats, 149);
    }

    function testFlightURIAfterBooking() public {
        vm.prank(owner);
        flightTicket.bookSeat{value: 0.001 ether}(0);
        string memory uri = flightTicket.getFlightURI(0);
        assertTrue(bytes(uri).length > 50);
    }

    function testFlightDetailsPersistence() public {
        FlightTicket.Flight memory flight1 = flightTicket.getFlight(0);
        FlightTicket.Flight memory flight2 = flightTicket.getFlight(1);
        assertEq(flight1.airportOrigin, "LAX");
        assertEq(flight2.airportOrigin, "SFO");
    }

    function testBookSeatSuccess() public {
        vm.prank(owner);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);

        vm.prank(passenger);
        flightTicket.bookSeat{value: 0.001 ether}(0);

        uint256 availableSeats = flightTicket.getSeatStatus(0);
        assertEq(availableSeats, 149);
    }

    function testBookSeatInvalidFlight() public {
        vm.expectRevert(FlightTicket.FlightTicket_FlightDoesNotExist.selector);
        vm.prank(passenger);
        flightTicket.bookSeat{value: 0.001 ether}(99);
    }

    function testBookSeatNoSeatsAvailable() public {
        vm.prank(owner);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 1);

        vm.prank(passenger);
        flightTicket.bookSeat{value: 0.001 ether}(0);

        vm.expectRevert(FlightTicket.FlightTicket_NoSeatsAvailable.selector);
        vm.prank(address(3));
        flightTicket.bookSeat{value: 0.001 ether}(0);
    }

    function testBookSeatIncorrectPayment() public {
        vm.prank(owner);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);

        vm.expectRevert(FlightTicket.FlightTicket_IncorrectPaymentAmount.selector);
        vm.prank(passenger);
        flightTicket.bookSeat{value: 0.002 ether}(0);
    }

    function testBookSeatTooLate() public {
        vm.prank(owner);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);

        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert(FlightTicket.FlightTicket_FlightTicketFinished.selector);
        vm.prank(passenger);
        flightTicket.bookSeat{value: 0.001 ether}(0);
    }

    function testBookSeatBalanceOverflow() public {
        vm.prank(owner);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);

        vm.expectRevert(FlightTicket.FlightTicket_BalanceOverflow.selector);
        vm.prank(passenger);
        flightTicket.bookSeat{value: type(uint96).max}(0);
    }

    function testBookSeatUsingBalanceSuccess() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        assertEq(flightTicket.getSeatStatus(flightId), 149);
    }

    function testBookSeatFails_InvalidFlight() public {
        vm.expectRevert(FlightTicket.FlightTicket_FlightDoesNotExist.selector);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(999);
    }

    function testBookSeatFails_NoSeatsAvailable() public {
        for (uint256 i = 0; i < 150; i++) {
            vm.prank(passenger);
            flightTicket.bookSeatUsingPassengerBalance(flightId);
        }
        vm.expectRevert(FlightTicket.FlightTicket_NoSeatsAvailable.selector);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
    }

    function testBookSeatFails_InsufficientBalance() public {
        vm.prank(owner);
        flightTicket.addBalance(passenger, 0.0001 ether);
        vm.expectRevert(FlightTicket.FlightTicket_IncorrectPaymentAmount.selector);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
    }

    function testBookSeatFails_LastMinuteBooking() public {
        vm.warp(block.timestamp + 10 days - 30 minutes);
        vm.expectRevert(FlightTicket.FlightTicket_FlightTicketFinished.selector);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
    }

    function testBookSeatReducesBalance() public {
        uint256 initialBalance = flightTicket.getPassengerBalance(passenger);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        assertEq(flightTicket.getPassengerBalance(passenger), initialBalance - 0.001 ether);
    }

    function testBookSeatIncrementsSeatCount() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        (,,,, uint256 bookedSeats,,,,) = flightTicket.getFlight(flightId);
        assertEq(bookedSeats, 1);
    }

    function testBookSeatIncrementsFlightBalance() public {
        uint256 initialBalance = flightTicket.getFlightBalance(flightId);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        assertEq(flightTicket.getFlightBalance(flightId), initialBalance + 0.001 ether);
    }

    function testBookSeatEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_SeatBooked(passenger, flightId);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
    }

    function testBookSeatMintsToken() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        assertEq(flightTicket.balanceOf(passenger, flightId), 1);
    }
}