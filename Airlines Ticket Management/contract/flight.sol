// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./ticket.sol";


contract Flight {

    address payable _airline;

    enum FlightStatus { UNKNOWN, ONTIME, DELAYED, CANCELLED }
    
    struct FlightData {
        string       name;
        uint         departure_time;
        uint         delayed_time;
        uint8        total_seats;
        uint8        booked_seats;
        uint8        available_seats;
        uint         price_per_seat;
        FlightStatus status;		
        uint         status_update_time;
	}

    FlightData public _flight_data;

    mapping( uint => Ticket ) _tickets;  // ( PNR => Ticket )
    uint[] _pnr_indices;
    uint g_pnr = 12345;

    constructor ( address payable aireline_, string memory airline_name_, uint flight_time_, uint8 total_seats_, uint price_per_seat_ ) {

        _airline = aireline_;
                                    
        _flight_data = FlightData({
                                    name:               airline_name_,
                                    departure_time:     flight_time_,
                                    delayed_time:       0,
                                    total_seats:        total_seats_,
                                    booked_seats:       0,
                                    available_seats:    total_seats_,
                                    price_per_seat:     price_per_seat_,
                                    status:             FlightStatus.UNKNOWN,
                                    status_update_time: 0
                            });
    }

    // The status can be updated only once.
    function update_status( address airline_, uint8 status_, uint delayed_time_, uint now_ ) public returns( bool ) {
        require( airline_ == _airline, "Only corresponding airline can update the flight status.");
        require( _flight_data.status == FlightStatus.UNKNOWN, "The flight status is already updated." );

        //uint now_ = block.timestamp; // Current timestamp
        require( now_ < (_flight_data.departure_time + 24*60*60), "The Airline can update the status only within 24 hours of the flight start time." );
        
        if ( status_ == 0 ) {
            _flight_data.status = FlightStatus.ONTIME;
        }
        else if ( status_ == 1 ) {
            _flight_data.delayed_time = delayed_time_;
            _flight_data.status = FlightStatus.DELAYED;
        }
        else if ( status_ == 2 ) {
            _flight_data.status = FlightStatus.CANCELLED;
        }

        _flight_data.status_update_time = now_;

        return true;
    }

    function book_seats(  address payable customer, uint8 requested_seat_count, uint payment ) public payable returns( uint ) {
        
        require( requested_seat_count > 0, "Please provide a valid number of seat count.");

        if ( _flight_data.available_seats < requested_seat_count ) {
            revert( "The number of seats reqeusted are not available in the flight." );
        }

        uint ticket_price = requested_seat_count * _flight_data.price_per_seat;
        require( payment == ticket_price, "Please payment with exact amount." );

        // Book the seats:
        _flight_data.booked_seats    += requested_seat_count;
        _flight_data.available_seats -= requested_seat_count;

        // Generate a new PNR:
        while ( _is_pnr_exist( g_pnr ) == true ) {
            g_pnr += 1;
        }

        // Make a new Ticket contract:    
        Ticket ticket =  new Ticket( _airline, customer, _flight_data.name, _flight_data.departure_time, requested_seat_count, ticket_price, g_pnr );
        
        _tickets[g_pnr] = ticket;
        _pnr_indices.push( g_pnr );

        return g_pnr;
    }

    function cancle_flight( address airline_, uint now_ ) public {

        require( _flight_data.status == FlightStatus.UNKNOWN, "The flight is not cancellable." );
        
        //uint now_ = block.timestamp; // Current timestamp
        require( now_ < (_flight_data.departure_time + 24*60*60), "This action is not allowed after 24 hours of the flight start time." );

        uint array_length = _pnr_indices.length;
        uint pnr;
        Ticket ticket;

        for( uint i=0; i<array_length; i++ ) {
            pnr     = _pnr_indices[i];
            ticket = _tickets[pnr];

            ticket.cancel_by_airline( airline_ );
        }
    
        //uint now_ = block.timestamp; // Current timestamp

        _flight_data.status             = FlightStatus.CANCELLED;
        _flight_data.status_update_time = now_;

    }

    function cancel_ticket( address customer_, uint pnr_, uint now_ ) public {
        require( _is_pnr_exist( pnr_ ) == true, "The ticket does not exist for the PNR." );

        /* 
            Define multiple cancellation penalties in favour of the airline:
            If customer cancels before 24 hours of flight departure time, then refund with 40% penalty.
            If customer cancels after 24 hours but before 2 hours of flight departure time, then refund with 60% penalty.
            If customer cancels after that time, then 100% penalty will be applied.
        */
        uint8 penalty_percentage_ = 0;
        //uint  now_ = block.timestamp; // Current timestamp
        uint time_diff =  _flight_data.departure_time - now_;

        if ( time_diff > (24*60*60) ) { // Cancelling before 24 hours of flight departure time.
            penalty_percentage_ = 40;

        } else if ( time_diff > (2*60*60) ) { // Cancelling after 24 hours but before 2 hours of flight departure time.
            penalty_percentage_ = 60;

        } else {
            // penalty_percentage_ = 100;
            revert( "The ticket can not be cancelled now." );
        }

        _tickets[pnr_].cancel_by_customer( customer_, penalty_percentage_ );
    }

    function claim_refund( address customer_, uint pnr_, uint now_ ) public {
        //uint  now_ = block.timestamp; // Current timestamp
        
        require( (now_ - _flight_data.departure_time) > (24*60*60), "The claim can only be made after 24 hours of flight departure time." );

        require( _is_pnr_exist( pnr_ ) == true, "The ticket does not exist for the PNR." );

        /* 
            Decide the refund percentage on customer:
            1. If the flight status is not updated and it's still UNKNOWN, then refund with 100%.
            2. If the flight status is CANCELLED, that means the full refund has already been made to 
               the customer and the ticket contract's status is already set to SETTLED.
            3. If the flight status is DELAYED, then refund with 20%.
            4. If the flight status is ONTIME, then refund with 0%.
        */
        uint8 refund_percentage_ = 0;

        if( _flight_data.status == FlightStatus.UNKNOWN ) { // The airline did not update the status.
            refund_percentage_ = 100;

        } else if( _flight_data.status == FlightStatus.CANCELLED ) { // Anyway the ticket contract is already in SETTLED state. So this condition is redundant.
            refund_percentage_ = 100;

        } else if( _flight_data.status == FlightStatus.DELAYED ) {
            // Define multiple delay penalties in favour of the customer.
            uint time_delayed = _flight_data.delayed_time - _flight_data.departure_time;

            if ( time_delayed < (1*60*60) ) { // Less than 1 hour delay.
                refund_percentage_ = 10;

            } else if ( time_delayed < (5*60*60) ) { // Delay time is between 1 hours to 5 hours.
                refund_percentage_ = 50;

            } else { // Delay is more than 5 hours.
                refund_percentage_ = 100; // Full refund.
            }

        } else if( _flight_data.status == FlightStatus.ONTIME ) {
            refund_percentage_ = 0;
        }

        _tickets[pnr_].claimed_by_customer( customer_, refund_percentage_ );
    }

    function get_customer_ticket( uint pnr_ ) public view returns( Ticket.TicketData memory ) { //uint8
        require( _is_pnr_exist( pnr_ ) == true, "The ticket does not exist for the PNR." );

        Ticket customer_ticket = _tickets[pnr_];

        return customer_ticket.get_ticket_data();
        //return customer_ticket.get_seats();
    }

    function _is_pnr_exist( uint pnr ) private view returns( bool ) {
        Ticket ticket = _tickets[pnr];

        bytes32 data = bytes32( abi.encodePacked( ticket) );
        bytes32 NULL = bytes32( uint(0) );

        return data != NULL;
    }
	
	/*
    function get_flight_data() public view returns( FlightData memory ) {
        return _flight_data;
    }
	*/
}