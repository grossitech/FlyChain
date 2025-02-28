// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "../../contracts/FlightTicket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlightTicketTest is Test {
    FlightTicket private flightTicket;
    address private owner = address(1);
    address private nonOwner = address(2);

    // Setup runs before each test
    function setUp() public {
        vm.startPrank(owner);
        flightTicket = new FlightTicket(owner);
        vm.stopPrank();
    }

    // Test 1: Only owner can add flights
    function test_RevertIfNotOwner() public {
        vm.expectRevert();
        vm.prank(nonOwner);
        flightTicket.addFlight("GRU", "CGH", uint48(block.timestamp + 8 days), "B737", 200);
    }

    // Test 2: Revert for invalid origin IATA code (must be 3 characters)
    function test_RevertIfInvalidOriginIATA() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_InvalidIATA.selector, 
                "GR", 
                "CGH"
            )
        );
        flightTicket.addFlight("GR", "CGH", uint48(block.timestamp + 8 days), "B737", 200);
        vm.stopPrank();
    }

    // Test 3: Revert for invalid destination IATA code (must be 3 characters)
    function test_RevertIfInvalidDestinationIATA() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_InvalidIATA.selector, 
                "GRU", 
                "CG"
            )
        );
        flightTicket.addFlight("GRU", "CG", uint48(block.timestamp + 8 days), "B737", 200);
        vm.stopPrank();
    }

    // Test 4: Revert if departure time is less than 7 days from now
    function test_RevertIfDepartureTimeTooSoon() public {
        vm.startPrank(owner);
        uint256 nowTime = block.timestamp;
        // Converte departureTime para uint256 para combinar com a definição do erro
        uint48 departureTime = uint48(nowTime + 7 days - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_FlightCannotBeLessThanOneWeek.selector, 
                uint256(departureTime), 
                nowTime
            )
        );
        flightTicket.addFlight("GRU", "CGH", departureTime, "B737", 200);
        vm.stopPrank();
    }

    // Test 5: Revert if aircraft model is empty
    function test_RevertIfEmptyAircraft() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_AircraftCannotBeEmpty.selector, 
                ""
            )
        );
        flightTicket.addFlight("GRU", "CGH", uint48(block.timestamp + 8 days), "", 200);
        vm.stopPrank();
    }

    // Test 6: Revert if total seats is zero
    function test_RevertIfZeroSeats() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                FlightTicket.FlightTicket_SeatsMustBeGreaterThanZero.selector, 
                0
            )
        );
        flightTicket.addFlight("GRU", "CGH", uint48(block.timestamp + 8 days), "B737", 0);
        vm.stopPrank();
    }

    // Test 7: Successful flight creation with valid parameters
    function test_AddFlightSuccess() public {
        vm.startPrank(owner);
        uint48 departureTime = uint48(block.timestamp + 8 days);
        uint256 expectedFlightId = flightTicket.s_flightId();
        flightTicket.addFlight("GRU", "CGH", departureTime, "B737", 200);

        (
            uint48 departureTimeStored,
            uint16 totalSeats,
            uint16 seatsBooked,
            uint96 price,
            uint96 balance,
            string memory origin,
            string memory destination,
            string memory aircraft
        ) = flightTicket.s_flights(expectedFlightId);

        assertEq(origin, "GRU", "Origin incorreta");
        assertEq(destination, "CGH", "Destination incorreta");
        assertEq(departureTimeStored, departureTime, "Horario incorreto");
        assertEq(aircraft, "B737", "Modelo de aeronave incorreto");
        assertEq(totalSeats, 200, "Total de assentos incorreto");
        assertEq(seatsBooked, 0, "Assentos reservados devem ser zero");
        assertEq(price, 0.001 ether, "Preco padrao incorreto");
        vm.stopPrank();
    }

    // Test 8: Verify flight ID increments correctly
    function test_FlightIdIncrement() public {
        vm.startPrank(owner);
        uint256 initialId = flightTicket.s_flightId();

        flightTicket.addFlight("GRU", "CGH", uint48(block.timestamp + 8 days), "B737", 200);
        assertEq(flightTicket.s_flightId(), initialId + 1, "Flight ID should increment by 1");

        flightTicket.addFlight("CGH", "GRU", uint48(block.timestamp + 9 days), "A320", 180);
        assertEq(flightTicket.s_flightId(), initialId + 2, "Flight ID should increment by 2");
        vm.stopPrank();
    }

    // Test 9: Verify FlightCreated event emission
    function test_EventEmitted() public {
        vm.startPrank(owner);
        uint48 departureTime = uint48(block.timestamp + 8 days);
        uint256 expectedFlightId = flightTicket.s_flightId();
        vm.expectEmit(true, true, true, true);
        emit FlightTicket.FlightTicket_FlightCreated(
            expectedFlightId,
            "GRU",
            "CGH",
            departureTime,
            "B737",
            200,
            0.001 ether
        );
        flightTicket.addFlight("GRU", "CGH", departureTime, "B737", 200);
        vm.stopPrank();
    }
}
