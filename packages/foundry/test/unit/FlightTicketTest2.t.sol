// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../../contracts/FlightTicket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
testClaimPassengerBalanceSuccess
*/

contract FlightTicketTest2 is Test {
    FlightTicket private flightTicket;
    address private owner = address(0x123);
    address public passenger = address(2);
    uint256 flightId = 0;

    struct Flight {
        uint48 departureTime;
        uint16 totalSeats;
        uint16 seatsBooked;
        uint96 price;
        uint96 balance;
        string airportOrigin;
        string airportDestination;
        string aircraftModel;
    }

    /// @dev Mapping from flight ID to Flight struct.
    mapping(uint256 => Flight) public s_flights;

    function setUp() public {
        vm.startPrank(owner); // Simulate actions as the owner
        flightTicket = new FlightTicket(owner); // Initialize contract
        vm.deal(passenger, 1 ether);
        
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
        flightTicket.addFlight("SFO", "ORD", uint48(block.timestamp + 10 days), "Airbus A320", 200);

        Flight memory flight1 = Flight({
            departureTime: uint48(block.timestamp + 8 days),
            totalSeats: 150,
            seatsBooked: 0,
            price: 0.001 ether,
            balance: 0,
            airportOrigin: "LAX",
            airportDestination: "JFK",
            aircraftModel: "Boeing 737"
        });
        s_flights[1] = flight1;

        Flight memory flight2 = Flight({
            departureTime: uint48(block.timestamp + 8 days),
            totalSeats: 200,
            seatsBooked: 0,
            price: 0.001 ether,
            balance: 0,
            airportOrigin: "SFO",
            airportDestination: "ORD",
            aircraftModel: "Airbus A320"
        });
        s_flights[2] = flight2;
    }

    // Test 1: Valid flight creation
    function testAddFlightValid() public {
        FlightTicket.Flight memory flight = flightTicket.getFlight(1);
        assertEq(flight.airportOrigin, "LAX");
        assertEq(flight.airportDestination, "JFK");
        assertEq(flight.aircraftModel, "Boeing 737");
        assertEq(flight.totalSeats, 150);
    }

    // Test 2: Invalid IATA code for origin
    function testAddFlightInvalidOriginIATA() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_InvalidIATA.selector,
                "LA",
                "JFK"
            )
        );
        flightTicket.addFlight("LA", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    // Test 3: Invalid IATA code for destination
    function testAddFlightInvalidDestinationIATA() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_InvalidIATA.selector,
                "LAX",
                "NY"
            )
        );
        flightTicket.addFlight("LAX", "NY", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    // Test 4: Flight departure time is too soon
    function testAddFlightDepartureTimeTooSoon() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_FlightCannotBeLessThanOneWeek.selector,
                uint48(block.timestamp + 6 days),
                uint48(block.timestamp)
            )
        );
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 6 days), "Boeing 737", 150);
    }

    // Test 5: Empty aircraft model
    function testAddFlightEmptyAircraftModel() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_AircraftCannotBeEmpty.selector,
                ""
            )
        );
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "", 150);
    }

    // Test 6: Zero total seats
    function testAddFlightZeroTotalSeats() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_SeatsMustBeGreaterThanZero.selector,
                0
            )
        );
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
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                nonOwner
            )
        );
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    // Test 9: Flight created with correct price
    function testAddFlightCorrectPrice() public {
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
        FlightTicket.Flight memory flight = flightTicket.getFlight(3);
        assertEq(flight.price, 0.001 ether);
    }

    // Test 10: Event emitted on flight creation
    function testAddFlightEventEmitted() public {
        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_FlightCreated(3, "LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150, 0.001 ether);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    function testAddFlightSameOriginAndDestinationIATA() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_InvalidIATA.selector,
                "LAX",
                "LAX"
            )
        );
        flightTicket.addFlight("LAX", "LAX", uint48(block.timestamp + 8 days), "Boeing 737", 150);
    }

    function testGetFlightInvalid() public {
        vm.expectRevert();
        flightTicket.getFlight(100); // Non-existent flight
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

    function testAddPassengerBalance() public {
        // Expect revert when checking balance before adding any funds
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_PassengerWithoutBalance.selector,
                owner
            )
        );
        vm.startPrank(owner);
        flightTicket.getPassengerBalance(owner);
        vm.stopPrank();

        // Add balance and check if it is correctly updated
        vm.deal(owner, 1 ether); // Ensure the owner has enough funds
        vm.startPrank(owner);
        flightTicket.addPassengerBalance{value: 0.5 ether}();
        vm.stopPrank();

        vm.startPrank(owner);
        assertEq(flightTicket.getPassengerBalance(passenger), 0.5 ether);
        vm.stopPrank();
    }

    function testAddPassengerBalanceMultipleTimes() public {
        vm.deal(owner, 1 ether); // Ensure the owner has enough funds
        vm.startPrank(owner);
        flightTicket.addPassengerBalance{value: 0.3 ether}();
        flightTicket.addPassengerBalance{value: 0.2 ether}();
        vm.stopPrank();
        vm.startPrank(owner);
        assertEq(flightTicket.getPassengerBalance(passenger), 0.5 ether);
        vm.stopPrank();
    }

    function testGetPassengerBalanceFailsZeroBalance() public {
        vm.prank(passenger);
        vm.expectRevert(FlightTicket.FlightTicket_PassengerWithoutBalance.selector);
        flightTicket.getPassengerBalance(passenger);
    }

    function testBookSeatUsingBalanceSuccess() public {
        vm.prank(owner);
        flightTicket.addFlight("LAX", "JFK", uint48(block.timestamp + 8 days), "Boeing 737", 150);

        vm.prank(owner);
        flightTicket.addPassengerBalance();

        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(3);
        assertEq(flightTicket.getPassengerBalance(passenger), 0); // Adjusted expected balance
    }

    function testBookSeatFailsInvalidFlight() public {
        vm.prank(passenger);
        vm.expectRevert(abi.encodeWithSelector(FlightTicket.FlightTicket_FlightDoesNotExist.selector, 3));
        flightTicket.bookSeat{value: 0.001 ether}(999); // Assuming 999 is an invalid flight ID
    }

    function testBookSeatFailsNoSeatsAvailable() public {
        for (uint256 i = 0; i < 150; i++) {
            vm.prank(passenger);
            flightTicket.bookSeatUsingPassengerBalance(flightId);
        }
        vm.expectRevert(FlightTicket.FlightTicket_NoSeatsAvailable.selector);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
    }

    function testBookSeatFailsInsufficientBalance() public {
        vm.prank(owner);
        flightTicket.addPassengerBalance{value: 0.0001 ether}();
        vm.expectRevert(FlightTicket.FlightTicket_IncorrectPaymentAmount.selector);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
    }

    function testBookSeatFailsLastMinuteBooking() public {
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

        FlightTicket.Flight memory flight = flightTicket.getFlight(flightId);
        assertEq(flight.seatsBooked, 1);
    }

    function testBookSeatIncrementsFlightBalance() public {
        uint256 initialBalance = flightTicket.getFlightBalance(flightId);
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        assertEq(flightTicket.getFlightBalance(flightId), initialBalance + 0.001 ether);
    }

    function testBookSeatEmitsEvent() public {
        // Ensure the owner has enough funds
        vm.deal(owner, 1 ether);

        // Ensure the passenger has enough balance
        vm.startPrank(owner);
        flightTicket.addPassengerBalance{value: 0.0011 ether}();
        vm.stopPrank();

        // Ensure the flight ID exists
        vm.startPrank(owner);
        flightTicket.addFlight("LAX", "ORD", uint48(block.timestamp + 12 days), "Boeing 747", 300);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_SeatBooked(passenger, 3); // Adjusted flight ID to 3
        vm.startPrank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(3); // Adjusted flight ID to 3
        vm.stopPrank();
    }

    function testBookSeatMintsToken() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        assertEq(flightTicket.balanceOf(passenger, flightId), 1);
    }

    function testCancelTicketSuccess() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        vm.prank(passenger);
        flightTicket.cancelTicket(flightId);
        assertEq(flightTicket.balanceOf(passenger, flightId), 0);
    }

    function testCancelTicketFailsNoTicket() public {
        vm.expectRevert(FlightTicket.FlightTicket_NoTicketFound.selector);
        vm.prank(passenger);
        flightTicket.cancelTicket(flightId);
    }

    function testCancelTicketFailsFlightDoesNotExist() public {
        vm.expectRevert(FlightTicket.FlightTicket_FlightDoesNotExist.selector);
        vm.prank(passenger);
        flightTicket.cancelTicket(999);
    }

    function testCancelTicketFailsTooLate() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        vm.warp(block.timestamp + 10 days - 30 minutes);
        vm.expectRevert(FlightTicket.FlightTicket_TooLateToCancel.selector);
        vm.prank(passenger);
        flightTicket.cancelTicket(flightId);
    }

    function testCancelTicketRefundsBalance() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        uint256 initialBalance = flightTicket.getPassengerBalance(passenger);
        vm.prank(passenger);
        flightTicket.cancelTicket(flightId);
        assertEq(flightTicket.getPassengerBalance(passenger), initialBalance + 0.001 ether);
    }

    function testCancelTicketDecrementsSeatCount() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        vm.prank(passenger);
        flightTicket.cancelTicket(flightId);
        FlightTicket.Flight memory flight = flightTicket.getFlight(flightId);
        assertEq(flight.seatsBooked, 0);
    }

    function testCancelTicketDecrementsFlightBalance() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        uint256 initialBalance = flightTicket.getFlightBalance(flightId);
        vm.prank(passenger);
        flightTicket.cancelTicket(flightId);
        assertEq(flightTicket.getFlightBalance(flightId), initialBalance - 0.001 ether);
    }

    function testCancelTicketEmitsEvent() public {
        vm.prank(passenger);
        flightTicket.bookSeatUsingPassengerBalance(flightId);
        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_TicketCancelled(passenger, flightId);
        vm.prank(passenger);
        flightTicket.cancelTicket(flightId);
    }

    function testClaimPassengerBalanceSuccess() public {
        // Add balance to the passenger
        vm.deal(passenger, 1 ether);
        vm.startPrank(passenger);
        flightTicket.addPassengerBalance{value: 1 ether}();
        vm.stopPrank();

        assertEq(flightTicket.getPassengerBalance(passenger), 1 ether);

        // Claim the balance
        uint256 initialBalance = passenger.balance;
        vm.startPrank(passenger);
        flightTicket.claimPassengerBalance();
        vm.stopPrank();

        // Check the balance after claiming
        assertEq(passenger.balance, initialBalance + 1 ether);
        vm.startPrank(passenger);
        assertEq(flightTicket.getPassengerBalance(passenger), 0);
        vm.stopPrank();
    }

    function testClaimPassengerBalanceFailsNoBalance() public {
        vm.expectRevert(abi.encodeWithSelector(
            FlightTicket.FlightTicket_PassengerWithoutBalance.selector, 
            passenger
        ));
        vm.startPrank(passenger);
        flightTicket.claimPassengerBalance();
        vm.stopPrank();
    }

    function testClaimPassengerBalanceTransfersFunds() public {
    // Add balance to the passenger
    vm.deal(passenger, 1 ether);
    vm.startPrank(passenger);
    flightTicket.addPassengerBalance{value: 1 ether}();
    vm.stopPrank();

    // Claim the balance
    uint256 initialBalance = passenger.balance;
    vm.startPrank(passenger);
    flightTicket.claimPassengerBalance();
    vm.stopPrank();

    // Check the balance after claiming
    assertEq(passenger.balance, initialBalance + 1 ether);
}

    function testClaimPassengerBalanceEmitsEvent() public {
       vm.deal(passenger, 1 ether);
        vm.startPrank(passenger);
        flightTicket.addPassengerBalance{value: 1 ether}();
        vm.stopPrank();

        // Expect the event to be emitted
        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_BalanceClaimed(passenger, 1 ether);

        // Claim the balance
        vm.startPrank(passenger);
        flightTicket.claimPassengerBalance();
        vm.stopPrank();
    }

    function testClaimPassengerBalanceFailsTwice() public {
    // Add balance to the passenger
    vm.deal(passenger, 1 ether);
    vm.startPrank(passenger);
    flightTicket.addPassengerBalance{value: 1 ether}();
    vm.stopPrank();

    // First claim (success)
    vm.startPrank(passenger);
    flightTicket.claimPassengerBalance();
    vm.stopPrank();

    // Second claim (fail)
    vm.startPrank(passenger);
    vm.expectRevert(abi.encodeWithSelector(
        FlightTicket.FlightTicket_PassengerWithoutBalance.selector, 
        passenger));
    flightTicket.claimPassengerBalance();
    vm.stopPrank();
}

    function testGetFlightBalanceSuccess() public {
        vm.startPrank(owner);
        uint256 balance = flightTicket.getFlightBalance(flightId);
        assertEq(balance, 0);
        vm.stopPrank();
    }

    function testWithdrawFlightFundsSuccess() public {
        vm.warp(block.timestamp + 11 days);
        vm.startPrank(owner);
        flightTicket.withdrawFlightFunds(flightId);
        assertEq(flightTicket.getFlightBalance(flightId), 0);
        vm.stopPrank();
    }

    function testWithdrawFlightFundsFailsNotOwner() public {
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, passenger));
    vm.startPrank(passenger);
    flightTicket.withdrawFlightFunds(flightId);
    vm.stopPrank();
    }

    function testWithdrawFlightFundsFailsBeforeDeparture() public {
        uint48 departureTime = s_flights[2].departureTime;
        vm.expectRevert(abi.encodeWithSelector(FlightTicket.FlightTicket_WaitForFlightTime.selector, flightId, departureTime));
        vm.startPrank(owner);
        flightTicket.withdrawFlightFunds(flightId);
    }
}