// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./ticket.sol";


contract Flight {

    enum FlightStatus { ONTIME, DELAYED, CANCELLED }
    
    struct FlightData {
        address payable airline;
        string  name;
        uint    departure_time;
        uint    delayed_time;
        uint8   total_seats;
        uint8   booked_seats;
        uint8   available_seats;
        uint32  price_per_seat;
        FlightStatus status;		
	}

    FlightData _flight_data;
    mapping( address => Ticket ) _ticket;


    constructor ( address payable _aireline, string memory _airline_name, uint _flight_time, uint8 _total_seats, uint32 _price_per_seat ) {

        _flight_data = FlightData({
                                    airline:         _aireline,
                                    name:            _airline_name,
                                    departure_time:  _flight_time,
                                    delayed_time:    0,
                                    total_seats:     _total_seats,
                                    booked_seats:    0,
                                    available_seats: _total_seats,
                                    price_per_seat:  _price_per_seat,
                                    status:          FlightStatus.ONTIME
                            });
    }

    function update_flight_time( address airline, uint new_time ) public returns( bool ) {
        require( airline == _flight_data.airline, "Only corresponding airline can update the flight time.");
        require( _flight_data.status == FlightStatus.ONTIME, "The flight is not available." );

        _flight_data.delayed_time = new_time;
        _flight_data.status = FlightStatus.DELAYED;

        return true;
    }

    function get_flight_status() public view returns( FlightStatus ) {
        return _flight_data.status;
    }

    function book_seats(  address payable customer, uint8 requested_seat_count ) public returns( uint ) {
        require( requested_seat_count > 0, "Please provide a valid number of seat count.");

        if ( _flight_data.available_seats < requested_seat_count ) {
            revert( "The number of seats reqeusted are not available in the flight." );
        }

        // Need to hold on the seats and wait for payments from customer.
        _flight_data.booked_seats    += requested_seat_count;
        _flight_data.available_seats -= requested_seat_count;

        // One customer can have only one ticket as of now.
        Ticket ticket =  new Ticket( _flight_data.airline, customer, _flight_data.name, _flight_data.departure_time, requested_seat_count, _flight_data.price_per_seat );
        
        _ticket[customer] = ticket;

        return ticket.get_payment_amount();
    }

    function make_payment( address payable customer, uint payment ) public payable {
        Ticket customer_ticket = _ticket[customer];

        customer_ticket.make_payment( payment );
    }

    function get_customer_ticket( address customer ) public view returns( uint8 ) {
        Ticket customer_ticket = _ticket[customer];

        return customer_ticket.get_seats();
    }

}