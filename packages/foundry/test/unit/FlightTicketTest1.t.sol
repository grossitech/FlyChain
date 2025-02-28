// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "../../contracts/FlightTicket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlightTicketTest1 is Test {
    FlightTicket private flightTicket;
    address private owner = address(1);
    address private user = address(2);
    uint256 private flightId = 0; 
    uint256 private ticketPrice = 1 ether;
    uint256 private totalSeats = 10;
    uint256 private departureTime = block.timestamp + 7 days; 

    function setUp() public {
        flightTicket = new FlightTicket(owner);

        uint48 testDepartureTime = uint48(block.timestamp + 7 days);
        departureTime = testDepartureTime;

        // Simulando a criação de um voo
        vm.startPrank(owner);
        flightTicket.addFlight("JFK", "LAX", testDepartureTime, "Boeing 737", 100);
        vm.stopPrank();
    }

    /// @dev Teste 1: Deve retornar o número correto de assentos disponíveis
    function testGetSeatStatus_ReturnsCorrectAvailableSeats() public {
        uint256 availableSeats = flightTicket.getSeatStatus(flightId);
        assertEq(availableSeats, totalSeats);
    }

    /// @dev Teste 2: Deve reverter se o ID do voo não existir
    function testGetSeatStatus_RevertsForInvalidFlightId() public {
        vm.expectRevert(FlightTicket.FlightTicket_FlightDoesNotExist.selector);
        flightTicket.getSeatStatus(flightId + 1);
    }

    /// @dev Teste 3: Deve permitir a reserva de um assento com pagamento correto
    function testBookSeat_SuccessfulBooking() public {
        vm.prank(user);
        flightTicket.bookSeat{value: ticketPrice}(flightId);
        
        uint256 availableSeats = flightTicket.getSeatStatus(flightId);
        assertEq(availableSeats, totalSeats - 1);
    }

    /// @dev Teste 4: Deve reverter se o voo não existir
    function testBookSeat_RevertsForInvalidFlightId() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(FlightTicket.FlightTicket_FlightDoesNotExist.selector, flightId + 1));
        flightTicket.bookSeat{value: ticketPrice}(flightId + 1);
    }

    /// @dev Teste 5: Deve reverter se não houver assentos disponíveis
    function testBookSeat_RevertsWhenNoSeatsAvailable() public {
        for (uint256 i = 0; i < totalSeats; i++) {
            vm.prank(address(uint160(i + 3))); // Simula múltiplos usuários reservando assentos
            flightTicket.bookSeat{value: ticketPrice}(flightId);
        }

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector
        (FlightTicket.FlightTicket_NoSeatsAvailable.selector, flightId, totalSeats, totalSeats));
        flightTicket.bookSeat{value: ticketPrice}(flightId);
    }

    /// @dev Teste 6: Deve reverter se o pagamento estiver incorreto
    function testBookSeat_RevertsForIncorrectPayment() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector
        (FlightTicket.FlightTicket_IncorrectPaymentAmount.selector, flightId, 0.5 ether, ticketPrice));
        flightTicket.bookSeat{value: 0.5 ether}(flightId);
    }

    /// @dev Teste 7: Deve reverter se a reserva for feita muito perto da hora de partida
    function testBookSeat_RevertsWhenBookingTooCloseToDeparture() public {
        vm.warp(departureTime - 59 minutes); // Avança o tempo para 59 minutos antes da partida
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector
        (FlightTicket.FlightTicket_FlightTicketFinished.selector, departureTime - 1 hours));
        flightTicket.bookSeat{value: ticketPrice}(flightId);
    }
}
