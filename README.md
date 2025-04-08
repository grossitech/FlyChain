# FlyChain: Revolutionizing Airline Ticket Sales with Blockchain

<i>🏆 Winning project developed for the Modular Carnival Hackathon by Modular Crypto — February 2025.</i>

<img align=center src="https://github.com/Cyber0Ulmo/HKT-AT-0V/blob/develop/Flychain.png?raw=true">

## Overview

FlyChain (`FlightTicket.sol` contract) is an innovative solution that leverages blockchain technology to transform the process of selling and managing airline tickets. Built on the Scroll network, the project offers a transparent, efficient, and automated platform for both passengers and airlines.

## 🌍 Available Languages

- 🇺🇸 [English](README.md)
- 🇧🇷 [Português Brasileiro](README.pt-BR.md)

## Key Features

### For Passengers
- **Direct Booking**: Book seats directly through the smart contract.
- **Flexible Cancellation**: Cancel tickets up to one hour before the flight with automatic refunds.
- **Balance Management**: Deposit and withdraw funds from your contract account.
- **Full Transparency**: All transactions are recorded on the blockchain.

### For Airlines
- **Process Automation**: Significantly reduces operational costs.
- **Efficient Management**: Full control over flights, seats, and revenue.
- **Real-Time Data**: Instant access to sales and occupancy information.

## Technologies Used

- **Solidity**: Smart contract programming language.
- **ERC1155**: Multi-token standard for representing tickets.
- **Scroll Network**: Provides scalability, low cost, and high-speed transactions.

## Smart Contract Functionalities

### Flight Management
- `addFlight`: Allows airlines to add new flights with complete details.
- `getFlight`: Retrieves detailed information about a specific flight.

### Seat Booking
- `bookSeat`: Enables passengers to book seats using Ether.
- `bookSeatUsingPassengerBalance`: Option to book using pre-deposited balance.

### Cancellation and Refund
- `cancelTicket`: Passengers can cancel bookings and receive automatic refunds.

### Balance Management
- `addPassengerBalance`: Passengers can deposit funds into their account.
- `claimPassengerBalance`: Allows withdrawal of accumulated balance.

### Airline-Specific Functions
- `getFlightBalance`: Check accumulated balance for each flight.
- `withdrawFlightFunds`: Allows fund withdrawal after flight departure.

## Advantages of the Scroll Network

- **Scalability**: Handles high transaction volumes.
- **Low Cost**: Reduced transaction fees.
- **High Speed**: Fast transaction confirmations.
- **Ethereum Compatibility**: Easy integration with the Ethereum ecosystem.

## Development Roadmap

### Phase 1: Customization and Security
- Implementation of an interactive seat map.
- Multiple seat selection.
- Wallet blocklist system.
- Airline-initiated cancellation feature.

### Phase 2: Feature Expansion
- Introduction of different seat categories.
- Flexible upgrade system.
- Loyalty program integration.
- Implementation of ticket resale.

### Phase 3: Integration and Partnerships
- API development for existing reservation systems.
- Partnerships with insurance providers.
- Support for multi-airline contracts.

### Phase 4: Advanced Innovations
- Tokenization of additional services (meals, extra baggage).
- Carbon offset system implementation.
- Integration with DeFi protocols for advanced financial options.

## How to Contribute

1. Fork this repository  
2. Create a branch for your feature (`git checkout -b feature/NewFeature`)  
3. Commit your changes (`git commit -m 'Add new feature'`)  
4. Push to the branch (`git push origin feature/NewFeature`)  
5. Open a Pull Request  

## Contact

Original project link: [https://github.com/Cyber0Ulmo/HKT-AT-0V](https://github.com/Cyber0Ulmo/HKT-AT-0V)

## License

This project is licensed under the MIT License.
