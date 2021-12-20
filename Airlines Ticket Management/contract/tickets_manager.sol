// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./flight.sol";


contract TicketManager {

    address _owner;

	// mappings( Flight_ID => Flight_Contract )
	mapping( bytes32 => Flight ) _flight_list;
	
    constructor ()  {
       _owner = msg.sender;
    }

    function add_flight( string memory flight_name, uint flight_time, uint8 total_seats, uint32 price_per_seat ) public returns( bool ) {
        address payable airline = payable( msg.sender );
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );

        // TBD: Put a check and revert if the flight already exists.

        Flight flight = new Flight( airline, flight_name, flight_time, total_seats, price_per_seat );

        _flight_list[flight_id] = flight;

        return true;
    }

    // Delayed flight by airline
    function update_flight_schedule( string memory flight_name, uint flight_time, uint new_time ) public returns( bool ) {
        address airline   = msg.sender;
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );

        Flight flight = _flight_list[flight_id];

        flight.update_flight_time( airline, new_time );

        return true;
    }

    // Cancel flight by airline.
    function cancle_flight() public {


    }

    function get_flight_status( string memory flight_name, uint flight_time ) public view returns( Flight.FlightStatus ) {
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        Flight flight     = _flight_list[flight_id];

        return flight.get_flight_status();
    }

    function book_ticket( string memory flight_name, uint flight_time, uint8 requested_seat_count ) public returns( uint ) {
        address payable _customer = payable( msg.sender );

        // TBD: Check and revert if the flight does not exist.

        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        Flight flight     = _flight_list[flight_id];

        return flight.book_seats( _customer, requested_seat_count);
    }

    function make_payment( string memory flight_name, uint flight_time ) public payable {
        address payable _customer = payable( msg.sender );

        // TBD: Check and revert if the flight does not exist.

        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        Flight flight     = _flight_list[flight_id];

        flight.make_payment( _customer, msg.value );
    }

    

    function cancel_ticket() public {


    }

    function claim_refund() public {


    }

    function get_ticket( string memory flight_name, uint flight_time ) public view returns( uint8 ){
        address _customer = msg.sender;

        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        Flight flight     = _flight_list[flight_id];

        return flight.get_customer_ticket( _customer );
    }
	
    /*
    function get_contract_owner() public view returns( address ) {
        return _owner;
    }
    */

    function __get_flight_id( string memory flight_name, uint flight_time ) private pure returns( bytes32 ) {
        return sha256( abi.encodePacked( flight_name, flight_time ) );
    }


}