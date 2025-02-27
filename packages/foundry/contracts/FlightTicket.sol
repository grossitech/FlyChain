// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract FlightTicket is ERC1155, Ownable {

    using Address for address;

    event FlightTicket_FlightCreated(
        uint256 _flightId,
        string _airportOrigin,
        string _airportDestination,
        uint256 _departureTime,
        string _aircraftModel,
        uint256 _totalSeats,
        uint256 _price);

    event FlightTicket_SeatBooked(address indexed _passenger, uint256 _flightId);
    event FlightTicket_TicketCancelled(address indexed _passenger, uint256 _flightId);
    event FlightTicket_BalanceClaimed(address _passenger, uint256 _amount);
    event FlightTicket_FundsWithdrawn(uint256 _flightId, uint256 _amount);
    error FlightTicket_AirportsCannotBeEmpty(string _airportOrigin, string _airportDestination);
    error FlightTicket_AircraftCannotBeEmpty(string _aircraftModel);
    error FlightTicket_FlightCannotBeLessThanOneDay(uint256 _departureTime, uint256 _currentTimestamp);
    error FlightTicket_SeatsMustBeGreaterThanZero(uint256 _totalSeats);
    error FlightTicket_FlightDoesNotExist(uint256 _flightId);
    error FlightTicket_NoSeatsAvailable(uint256 _flightId, uint256 _seatsBooked, uint256 _totalSeats);
    error FlightTicket_IncorrectPaymentAmount(uint256 _flightId, uint256 _seatsBooked, uint256 _totalSeats);
    error FlightTicket_FlightTicketFinished(uint256 _ticketFinished);
    error FlightTicket_NoTicketFound(address _sender, uint256 _flightId);
    error FlightTicket_PassengerWithoutBalance(address _passenger);
    error FlightTicket_WaitForFlightTime(uint256 _flightId, uint256 _departureTime);

    
/*
uint256 departureTime = recebe o block.timestamp
deve ser convertido para Unix timestamp na regra front/back antes de chegar no contrato
departureTime deve receber o block.timestamp do horario definido para decolagem do voo convertido
block.timestamp == 01/01/70 Unix timestamp
*/

    // eficiencia de vars*
    struct Flight {
        string airportOrigin; // GRU, CNF, CWB
        string airportDestination; // GRU, CNF, CWB
        uint256 departureTime;
        string aircraftModel;
        uint256 totalSeats;
        uint256 price;
        uint256 seatsBooked;
        uint256 balance;
    }

    mapping(uint256 => Flight) public s_flights;
    mapping(address => uint256) public s_passengerBalance;

    uint256 public s_flightId;

    constructor(address _initialOwner) ERC1155("https://localhost:5626/ticket/{id}") 
    Ownable(_initialOwner) {}

    function addFlight(
        string calldata _airportOrigin,
        string calldata _airportDestination,
        uint256 _departureTime,
        string calldata _aircraftModel,
        uint256 _totalSeats) external onlyOwner {
        if (bytes(_airportOrigin).length == 0 ||
            bytes(_airportDestination).length == 0) {
                revert FlightTicket_AirportsCannotBeEmpty(_airportOrigin, _airportDestination);
            }
        if (_departureTime <= block.timestamp + 1 days) 
        revert FlightTicket_FlightCannotBeLessThanOneDay(_departureTime, block.timestamp);
        if (bytes(_aircraftModel).length == 0) 
        revert FlightTicket_AircraftCannotBeEmpty(_aircraftModel);
        if (_totalSeats == 0) revert FlightTicket_SeatsMustBeGreaterThanZero(_totalSeats);

        // uint256 departureTime = block.timestamp + 14 days;
        uint256 price = 0.001 ether;

        emit FlightTicket_FlightCreated(s_flightId, _airportOrigin, 
        _airportDestination, _departureTime, _aircraftModel, _totalSeats, price);

        s_flights[s_flightId] = Flight(_airportOrigin, 
        _airportDestination, _departureTime, _aircraftModel, _totalSeats, price, 0, 0);

        ++s_flightId;
    }

    function getSeatStatus(uint256 _flightId) external view returns (uint256 availableSeats) {
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);
        return s_flights[_flightId].totalSeats - s_flights[_flightId].seatsBooked;
    }

    function bookSeat(uint256 _flightId) external payable {
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);

        if (block.timestamp >= s_flights[_flightId].departureTime - 1 hours) 
            revert FlightTicket_FlightTicketFinished(s_flights[_flightId].departureTime - 1 hours);
        
        Flight storage flight = s_flights[_flightId];

        if (flight.seatsBooked >= flight.totalSeats) 
            revert FlightTicket_NoSeatsAvailable(_flightId, flight.seatsBooked, flight.totalSeats);

        if (flight.price != msg.value)
            revert FlightTicket_IncorrectPaymentAmount(_flightId, msg.value, flight.price);

        ++flight.seatsBooked;
        flight.balance = flight.balance + msg.value;

        emit FlightTicket_SeatBooked(msg.sender, _flightId);

        _mint(msg.sender, _flightId, 1, "");
    }

    function bookSeatUsingPassengerBalance(uint256 _flightId) external {
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);

        if (block.timestamp >= s_flights[_flightId].departureTime - 1 hours) 
            revert FlightTicket_FlightTicketFinished(s_flights[_flightId].departureTime - 1 hours);
            
        Flight storage flight = s_flights[_flightId];

        if (flight.seatsBooked >= flight.totalSeats) 
            revert FlightTicket_NoSeatsAvailable(_flightId, flight.seatsBooked, flight.totalSeats);
            
        if(flight.price < s_passengerBalance[msg.sender])
            revert FlightTicket_IncorrectPaymentAmount(_flightId, s_passengerBalance[msg.sender], flight.price);

        s_passengerBalance[msg.sender] = s_passengerBalance[msg.sender] - flight.price;        
        ++flight.seatsBooked;
        flight.balance = flight.balance + flight.price;

        emit FlightTicket_SeatBooked(msg.sender, _flightId);

        _mint(msg.sender, _flightId, 1, "");
    }

    function _getPassengerBalance() external view returns(uint256 _balance) {
        if (s_passengerBalance[msg.sender] == 0) revert FlightTicket_PassengerWithoutBalance(msg.sender);
        return s_passengerBalance[msg.sender];
    }

    function cancelTicket(uint256 _flightId) external {
        if (balanceOf(msg.sender, _flightId) == 0) revert FlightTicket_NoTicketFound(msg.sender, _flightId);
        if (block.timestamp >= s_flights[_flightId].departureTime - 1 hours) {
            revert FlightTicket_FlightTicketFinished(s_flights[_flightId].departureTime - 1 hours);
        }

        Flight storage flight = s_flights[_flightId];

        --flight.seatsBooked;
        flight.balance = flight.balance - flight.price;

        s_passengerBalance[msg.sender] = s_passengerBalance[msg.sender] + flight.price;

        _burn(msg.sender, _flightId, 1);

        emit FlightTicket_TicketCancelled(msg.sender, _flightId);
    }
    
    function claimPassengerBalance() external {
        if (s_passengerBalance[msg.sender] == 0) revert FlightTicket_PassengerWithoutBalance(msg.sender);

        uint256 amount = s_passengerBalance[msg.sender];
        s_passengerBalance[msg.sender] = 0;

        emit FlightTicket_BalanceClaimed(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getFlightBalance(uint256 _flightId) external view onlyOwner returns (uint256) {
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);
        return s_flights[_flightId].balance;
    }

    function withdrawFlightFunds(uint256 _flightId) external onlyOwner {
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);
        
        if (block.timestamp > s_flights[s_flightId].departureTime) 
        revert FlightTicket_WaitForFlightTime(_flightId, s_flights[s_flightId].departureTime);

        Flight storage flight = s_flights[_flightId];

        uint256 amount = flight.balance;
        flight.balance = 0;

        emit FlightTicket_FundsWithdrawn(_flightId, amount);

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}