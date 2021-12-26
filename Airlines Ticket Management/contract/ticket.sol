// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Ticket {

    address payable public _airline;
    address payable public _customer;

    enum TicketStatus { BOOKED, SETTLED }

    struct TicketData {
        string  flight_name;
        uint    flight_time;
        uint8   booked_seats;
        uint    total_price;
        uint    pnr;
	}

    TicketStatus _status;
    TicketData   _ticket_data;

    modifier instate( TicketStatus expected_status ) {
          
        require( _status == expected_status, "The ticket is not in expected state for this action." );
        _;
    }
                   
    constructor( address payable airline_, address payable customer_, string memory flight_name_, uint flight_time_, uint8 seat_count_, uint total_seat_, uint pnr_ ) payable {

        _airline  = airline_;
        _customer = customer_;
        _status   = TicketStatus.BOOKED;

        _ticket_data  = TicketData({
                                flight_name:  flight_name_,
                                flight_time:  flight_time_,
                                booked_seats: seat_count_,
                                total_price:  total_seat_,
                                pnr:          pnr_
                            });
    }

    function cancel_by_customer( address customer_, uint8 penalty_percentage_ ) instate( TicketStatus.BOOKED ) public {
        require( _customer == customer_, "Only ticket owner account can cancel the ticket." );
        
        _refund_payment( penalty_percentage_ );
       _status = TicketStatus.SETTLED;        
    }

    function cancel_by_airline( address airline_ ) instate( TicketStatus.BOOKED ) public {
        require( _airline == airline_, "Only airline account can cancel the ticket." );

        _refund_payment( 0 ); // penalty is 0% when cancelled by airline.
       _status = TicketStatus.SETTLED;        
    }

    function claimed_by_customer( address customer_, uint8 refund_percentage_ ) instate( TicketStatus.BOOKED ) public {
        require( _customer == customer_, "Only ticket owner account can claim the refund." );

        uint8 penalty_percentage_ = 100 - refund_percentage_;

        _refund_payment( penalty_percentage_ );
       _status = TicketStatus.SETTLED;        
    }

    function _refund_payment( uint8 penalty_percentage_ ) private {
        uint airline_part  = ( address(this).balance * penalty_percentage_ ) / 100;
        uint customer_part = address(this).balance - airline_part;
        
        _customer.transfer( customer_part );
        _airline.transfer( airline_part );
    }

    function claimed_by_airline( address airline_ ) instate( TicketStatus.BOOKED ) public payable {
        // After 24 hours of departure time, if the ticket is still with BOOKED status, then 
        // the contact amount can be claimed by the airline.
        require( _airline == airline_, "Only airline account can claim the ticket amount." );
        
        uint now_ = block.timestamp; // Current timestamp
        require( (now_ - _ticket_data.flight_time) > (24*60*60), "The airline can claim only after 24 hours of departure time." ) ;

        _airline.transfer( address(this).balance );
        _status = TicketStatus.SETTLED;
    }

    function get_ticket_data() public view returns( TicketData memory ) {
        return _ticket_data;
    }

    function get_ticket_owner_address() public view returns( address ) {
        return _customer;
    }

    function get_balance() public view returns (uint) {
        return address(this).balance;
    }

}