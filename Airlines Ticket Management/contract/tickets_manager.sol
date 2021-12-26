// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./flight.sol";
import "./ticket.sol";


contract TicketManager {

    address _owner;

	// mappings( Flight_ID => Flight_Contract )
	mapping( bytes32 => Flight ) _flight_list;
    bytes32[] _id_indices;

	
    constructor ()  {
       _owner = msg.sender;
    }

    /*************************************************************/
    /*                  API's required for Airlines              */
    /*************************************************************/
    function add_flight( string memory flight_name, uint flight_time, uint8 total_seats, uint price_per_seat ) public returns( bool ) {
        address payable airline = payable( msg.sender );
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );

        require( _is_flight_exist( flight_id ) == false, "The flight is already added." ); // The flight can be added only once.

        Flight flight = new Flight( airline, flight_name, flight_time, total_seats, price_per_seat );

        _flight_list[flight_id] = flight;
        _id_indices.push( flight_id );

        return true;
    }

    // Update flight status by airline
    function update_flight_status( string memory flight_name_, uint flight_time_, uint8 status_, uint delayed_time_, uint now_ ) public returns( bool ) {
        address airline   = msg.sender;
        bytes32 flight_id = __get_flight_id( flight_name_, flight_time_ );

        require( _is_flight_exist( flight_id ) == true, "The flight is not available." );

        Flight flight = _flight_list[flight_id];

        flight.update_status( airline, status_, delayed_time_, now_ );

        return true;
    }

    // Cancel flight by airline.
    function cancle_flight( string memory flight_name_, uint flight_time_, uint now_ ) public returns( bool ) {
        address airline_   = msg.sender;
        bytes32 flight_id = __get_flight_id( flight_name_, flight_time_ );

        require( _is_flight_exist( flight_id ) == true, "The flight is not available." );

        Flight flight = _flight_list[flight_id];

        flight.cancle_flight( airline_, now_ );

        return true;        
    }


    /*************************************************************/
    /*                  API's required for Customers             */
    /*************************************************************/

    function book_ticket( string memory flight_name, uint flight_time, uint8 requested_seat_count ) public payable returns( uint ) {
        address payable _customer = payable( msg.sender );

        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        require( _is_flight_exist( flight_id ) == true, "The flight is not available." );

        Flight flight = _flight_list[flight_id];

        return flight.book_seats( _customer, requested_seat_count, msg.value ); // Return PNR number.
    }
 
    function cancel_ticket( string memory flight_name, uint flight_time, uint pnr_, uint now_ ) public {
        address customer = msg.sender;
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        require( _is_flight_exist( flight_id ) == true, "The flight is not available." );

        Flight flight     = _flight_list[flight_id];

        return flight.cancel_ticket( customer, pnr_, now_ );
    }

    function claim_refund( string memory flight_name, uint flight_time, uint pnr_, uint now_ ) public {
        address customer = msg.sender;
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        require( _is_flight_exist( flight_id ) == true, "The flight is not available." );

        Flight flight     = _flight_list[flight_id];

        return flight.claim_refund( customer, pnr_, now_ );
    }

    function get_ticket( string memory flight_name, uint flight_time, uint pnr_ ) public view returns( Ticket.TicketData memory ) {
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        require( _is_flight_exist( flight_id ) == true, "The flight is not available." );

        Flight flight     = _flight_list[flight_id];

        return flight.get_customer_ticket( pnr_ );
    }

 
    /*************************************************************/
    /*      Private methods required for the public API's        */
    /*************************************************************/

    function __get_flight_id( string memory flight_name, uint flight_time ) private pure returns( bytes32 ) {
        return sha256( abi.encodePacked( flight_name, flight_time ) );
    }


    function _is_flight_exist( bytes32 flight_id ) private view returns( bool ) {
        Flight flight = _flight_list[flight_id];

        bytes32 data = bytes32( abi.encodePacked( flight) );
        bytes32 NULL = bytes32( uint(0) );

        return data != NULL;
    }


    /*************************************************************/
    /*               Common public APIs                          */
    /*************************************************************/
	
    /*
    function get_contract_owner() public view returns( address ) {
        return _owner;
    }

    function get_balance() public view returns (uint) {
        return address(this).balance;
    }
 
    function get_flight_details( string memory flight_name, uint flight_time ) public view returns( Flight.FlightData memory ){
        bytes32 flight_id = __get_flight_id( flight_name, flight_time );
        Flight flight     = _flight_list[flight_id];

        return flight.get_flight_data();
    }
    */
}