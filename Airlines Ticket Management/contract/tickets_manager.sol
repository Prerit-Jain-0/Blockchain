// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.8.11;


import "./flight.sol";
import "./ticket.sol";


contract TicketManager {

    address _owner;
    address _refund_rules = 0x2557F4c8Ba4BE59eDDAbfd26dF4ECd7F2e678f1d;

	// mappings( Flight_ID => Flight_Contract )
	mapping( bytes32 => Flight ) _flight_list;
    	
    constructor ()  {
       _owner = msg.sender;
    }

    modifier flight_exists(bytes32 flight_id_){
        Flight flight = _flight_list[flight_id_];

        require( _is_flight_exist( flight ), "The flight is not available." );    
        _;

    }

    /*************************************************************/
    /*                  API's required for Airlines              */
    /*************************************************************/

    // Adding a new flight by airline.
    function add_flight( bytes32 flight_id_, uint flight_time_, uint8 total_seats_, uint price_per_seat_ ) public returns( bool ) {
        Flight flight = _flight_list[flight_id_];

        require( _is_flight_exist( flight ) == false, "The flight is already added." ); // The flight can be added only once.

        flight = new Flight( flight_time_, total_seats_, price_per_seat_,_refund_rules );
       
        _flight_list[flight_id_] = flight;

        return true;
    }

    // Update flight status by airline
    function update_flight_status( bytes32 flight_id_, uint8 status_, uint delayed_time_, uint now_ ) flight_exists( flight_id_ ) public returns( bool ) {
        Flight flight = _flight_list[flight_id_];

        return flight.update_status( status_, delayed_time_, now_ );
    }

    // Cancel flight by airline.
    function cancel_flight( bytes32 flight_id_, uint now_ ) public returns( bool ) {       
        return update_flight_status( flight_id_, 2, 0, now_);
    }

    //Claim price due from get_contract_owner
    function claim_ticket_price( bytes32 flight_id_, uint pnr_, uint now_ ) flight_exists( flight_id_ ) public returns ( bool ) {
        Flight flight = _flight_list[flight_id_];

        return flight.claim_ticket_price( pnr_, now_ );
    }


    /*************************************************************/
    /*                  API's required for Customers             */
    /*************************************************************/

    function book_ticket( bytes32 flight_id_, uint8 requested_seat_count_ ) flight_exists( flight_id_ ) public payable returns( uint ) {
        Flight flight = _flight_list[flight_id_];
        uint pnr = flight.book_seats{ value:msg.value }( requested_seat_count_ );

        return pnr; // Return PNR number.
    }
 
    function cancel_ticket( bytes32 flight_id_, uint pnr_, uint now_ ) flight_exists( flight_id_ )  public {        
        Flight flight = _flight_list[flight_id_];

        return flight.cancel_ticket( pnr_, now_ );
    }

    function claim_refund( bytes32 flight_id_, uint pnr_, uint now_ ) flight_exists( flight_id_ )  public {
        Flight flight = _flight_list[flight_id_];

        return flight.claim_refund(  pnr_, now_ );
    }

    function get_ticket( bytes32 flight_id_, uint pnr_ ) flight_exists( flight_id_ ) public view returns( uint, uint8, uint, uint ) {
        Flight flight = _flight_list[flight_id_];

        return flight.get_customer_ticket( pnr_ );
    }

 
    /*************************************************************/
    /*      Private methods required for the public API's        */
    /*************************************************************/

    function _is_flight_exist( Flight flight_ ) private pure returns( bool ) {
        
        bytes32 data = bytes32( abi.encodePacked( flight_ ) );
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
    */
    function update_refund_rules( address _refund_rules_address ) public {
        _refund_rules = _refund_rules_address;
    }
    
}