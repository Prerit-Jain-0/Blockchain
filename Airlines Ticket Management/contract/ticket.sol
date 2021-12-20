// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Ticket {

    address payable public _airline;
    address payable public _customer;

    enum TicketStatus { AWAIT_PAYMENT, AWAIT_DELIVERY, CANCELLED, REFUNDED, COMPLETED }

    struct TicketData {
        string  flight_name;
        uint    flight_time;
        uint8   booked_seats;
        uint    total_price;
	}

    TicketStatus _status;
    TicketData   _ticket;

    modifier instate( TicketStatus expected_status ) {
          
        require( _status == expected_status );
        _;
    }
                   
    constructor( address payable airline_, address payable customer_, string memory flight_name_, uint flight_time_, uint8 seat_count_, uint price_per_seat_ ) {

        _airline  = airline_;
        _customer = customer_;
        _status   = TicketStatus.AWAIT_PAYMENT;

        _ticket   = TicketData({
                                flight_name:  flight_name_,
                                flight_time:  flight_time_,
                                booked_seats: seat_count_,
                                total_price:  price_per_seat_ * seat_count_
                            });
    }

    function get_payment_amount( ) view public returns( uint ) {
        return _ticket.total_price;
    }

    function make_payment( uint payment ) instate( TicketStatus.AWAIT_PAYMENT ) public payable {
        require( payment == _ticket.total_price, "Please payment with exact amount." );
        // bring the money from cutomer to this contract.
        _status = TicketStatus.AWAIT_DELIVERY;
    }

    function confirm_delivery() instate( TicketStatus.AWAIT_DELIVERY ) public payable {
        _airline.transfer( address(this).balance );
        _status = TicketStatus.COMPLETED;
    }

    // Defining function to return payment
    function refund_payment() instate( TicketStatus.AWAIT_DELIVERY ) public {
        _customer.transfer( address(this).balance );
        _status = TicketStatus.REFUNDED;
    }

    function get_seats( ) public view returns( uint8 ) {
        return _ticket.booked_seats;
    }

}