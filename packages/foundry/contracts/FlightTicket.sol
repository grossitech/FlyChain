// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Flight Ticket Management System
 * @dev ERC1155-based flight ticket system with booking, cancellation, and fund management capabilities
 */
contract FlightTicket is ERC1155, Ownable {
    using Address for address;

    // Event declarations
    event FlightTicket_FlightCreated(
        uint256 indexed _flightId,
        string _airportOrigin,
        string _airportDestination,
        uint256 _departureTime,
        string _aircraftModel,
        uint256 _totalSeats,
        uint256 _price
    );
    event FlightTicket_SeatBooked(address indexed _passenger, uint256 indexed _flightId);
    event FlightTicket_TicketCancelled(address indexed _passenger, uint256 indexed _flightId);
    event FlightTicket_BalanceClaimed(address indexed _passenger, uint256 _amount);
    event FlightTicket_FundsWithdrawn(uint256 indexed _flightId, uint256 _amount);

    // Error declarations
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
    error FlightTicket_FlightAlreadyDeparted(uint256 _departureTime, uint256 _currentTimestamp);
    error FlightTicket_TooLateToCancel(uint256 _latestCancelTime, uint256 _currentTimestamp);
    error FlightTicket_TooLateToBook(uint256 _latestBookingTime, uint256 _currentTimestamp);

    /**
     * @dev Flight structure storing essential flight information
     * @param airportOrigin IATA code of departure airport
     * @param airportDestination IATA code of arrival airport
     * @param departureTime UNIX timestamp of departure
     * @param aircraftModel ICAO aircraft type designation
     * @param totalSeats Maximum seat capacity
     * @param price Ticket price in wei
     * @param seatsBooked Currently reserved seats
     * @param balance Accumulated funds for the flight
     */
    struct Flight {
        string airportOrigin;
        string airportDestination;
        uint256 departureTime;
        string aircraftModel;
        uint256 totalSeats;
        uint256 price;
        uint256 seatsBooked;
        uint256 balance;
    }

    // State variables
    mapping(uint256 => Flight) public s_flights;
    mapping(address => uint256) public s_passengerBalance;
    uint256 public s_flightId;

    /**
     * @notice Initializes the contract
     * @param _initialOwner Address of initial contract owner
     */
    constructor(address _initialOwner) 
        ERC1155("https://localhost:5626/ticket/{id}") 
        Ownable(_initialOwner) 
    {
        // Intentionally empty
    }

    /**
     * @notice Creates a new flight (Owner only)
     * @dev Implements strict input validation and CEI pattern
     * @param _airportOrigin 3-letter IATA airport code
     * @param _airportDestination 3-letter IATA airport code
     * @param _departureTime Future UNIX timestamp (min 24h from now)
     * @param _aircraftModel Aircraft type designation
     * @param _totalSeats Total available seats (must be > 0)
     */
    function addFlight(
        string calldata _airportOrigin,
        string calldata _airportDestination,
        uint256 _departureTime,
        string calldata _aircraftModel,
        uint256 _totalSeats
    ) external onlyOwner {
        // CHECKS //
        if (bytes(_airportOrigin).length == 0 || bytes(_airportDestination).length == 0) {
            revert FlightTicket_AirportsCannotBeEmpty(_airportOrigin, _airportDestination);
        }
        if (_departureTime < block.timestamp + 1 days) {
            revert FlightTicket_FlightCannotBeLessThanOneDay(_departureTime, block.timestamp);
        }
        if (bytes(_aircraftModel).length == 0) {
            revert FlightTicket_AircraftCannotBeEmpty(_aircraftModel);
        }
        if (_totalSeats == 0) {
            revert FlightTicket_SeatsMustBeGreaterThanZero(_totalSeats);
        }

        // EFFECTS //
        uint256 price = 0.001 ether;
        uint256 currentFlightId = s_flightId;
        
        s_flights[currentFlightId] = Flight(
            _airportOrigin,
            _airportDestination,
            _departureTime,
            _aircraftModel,
            _totalSeats,
            price,
            0,  // seatsBooked
            0   // balance
        );

        emit FlightTicket_FlightCreated(
            currentFlightId,
            _airportOrigin,
            _airportDestination,
            _departureTime,
            _aircraftModel,
            _totalSeats,
            price
        );

        // INTERACTIONS //
        s_flightId++;  // State change after event emission
    }

    /**
     * @notice Returns available seats for specified flight
     * @param _flightId ID of the flight to check
     * @return availableSeats Number of remaining seats
     */
    function getSeatStatus(uint256 _flightId) external view returns (uint256 availableSeats) {
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);
        return s_flights[_flightId].totalSeats - s_flights[_flightId].seatsBooked;
    }

    /**
     * @notice Books a seat on specified flight
     * @dev Implements CEI pattern with ERC1155 minting
     * @param _flightId ID of the flight to book
     */
    function bookSeat(uint256 _flightId) external payable {
        // CHECKS //
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

        // INTERACTIONS //
        _mint(msg.sender, _flightId, 1, "");  // ERC1155 internal interaction
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

        // INTERACTIONS //
        _mint(msg.sender, _flightId, 1, "");  // ERC1155 internal interaction
    }

    function _getPassengerBalance() external view returns(uint256 _balance) {
        if (s_passengerBalance[msg.sender] == 0) revert FlightTicket_PassengerWithoutBalance(msg.sender);
        return s_passengerBalance[msg.sender];
    }

    /**
     * @notice Cancels a booked ticket
     * @dev Implements strict validation and CEI pattern
     * @param _flightId ID of the flight to cancel
     */
    function cancelTicket(uint256 _flightId) external {
        // CHECKS //
        if (balanceOf(msg.sender, _flightId) == 0) revert FlightTicket_NoTicketFound(msg.sender, _flightId);
        if (block.timestamp >= s_flights[_flightId].departureTime - 1 hours) {
            revert FlightTicket_FlightTicketFinished(s_flights[_flightId].departureTime - 1 hours);
        }
        
        Flight storage flight = s_flights[_flightId];
        
        if (block.timestamp >= flight.departureTime) {
            revert FlightTicket_FlightAlreadyDeparted(flight.departureTime, block.timestamp);
        }
        if (block.timestamp >= flight.departureTime - 1 hours) {
            revert FlightTicket_TooLateToCancel(flight.departureTime, block.timestamp);
        }

        // EFFECTS //
        --flight.seatsBooked;
        flight.balance -= flight.price;
        s_passengerBalance[msg.sender] += flight.price;
        
        _burn(msg.sender, _flightId, 1);  // ERC1155 internal interaction
        emit FlightTicket_TicketCancelled(msg.sender, _flightId);
    }

    /**
     * @notice Withdraws accumulated passenger balance
     * @dev Implements pull payment pattern
     */
    function claimPassengerBalance() external {
        // CHECKS //
        if (s_passengerBalance[msg.sender] == 0) revert FlightTicket_PassengerWithoutBalance(msg.sender);

        uint256 amount = s_passengerBalance[msg.sender];
        if (amount == 0) revert FlightTicket_NoBalanceToClaim(msg.sender);

        // EFFECTS //
        s_passengerBalance[msg.sender] = 0;
        emit FlightTicket_BalanceClaimed(msg.sender, amount);

        // INTERACTIONS //
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Returns flight balance (Owner only)
     * @param _flightId ID of the flight to check
     * @return balance Current accumulated balance
     */
    function getFlightBalance(uint256 _flightId) external view onlyOwner returns (uint256) {
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);
        return s_flights[_flightId].balance;
    }

    /**
     * @notice Withdraws flight funds after departure (Owner only)
     * @dev Implements CEI pattern with fund transfer
     * @param _flightId ID of the flight to withdraw from
     */
    function withdrawFlightFunds(uint256 _flightId) external onlyOwner {
        // CHECKS //
        if (_flightId >= s_flightId) revert FlightTicket_FlightDoesNotExist(_flightId);
        
        Flight storage flight = s_flights[_flightId];
        if (block.timestamp < flight.departureTime) {
            revert FlightTicket_WaitForFlightTime(_flightId, flight.departureTime);
        }

        // EFFECTS //
        uint256 amount = flight.balance;
        flight.balance = 0;
        emit FlightTicket_FundsWithdrawn(_flightId, amount);

        // INTERACTIONS //
        (bool success, ) = msg.sender.call{value: amount}("");  // Consider using Address.sendValue
        require(success, "Transfer failed");
    }
}