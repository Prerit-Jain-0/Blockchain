// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.8.11;

import "./ticket.sol";


contract Flight {
    address _airline;
    address _contract_owner;
    address _refund_rules;
    
    enum FlightStatus { UNKNOWN, ONTIME, DELAYED, CANCELLED }
    
    struct FlightData {
        uint         departure_time;
        uint         delayed_time;
        uint8        total_seats;
        uint8        booked_seats;
        uint8        available_seats;
        uint         price_per_seat;
        FlightStatus status;		
	}

    FlightData public _flight_data;
    
    //     ( PNR  => Ticket )
    mapping( uint => Ticket ) _tickets;
    uint g_pnr = 0;

    constructor (  uint flight_time_, uint8 total_seats_, uint price_per_seat_,address _refund_rules_address ) {
        _airline = tx.origin;
        _contract_owner = msg.sender;
        _refund_rules = _refund_rules_address;
                                    
        _flight_data = FlightData({
                                    departure_time:     flight_time_,
                                    delayed_time:       0,
                                    total_seats:        total_seats_,
                                    booked_seats:       0,
                                    available_seats:    total_seats_,
                                    price_per_seat:     price_per_seat_,
                                    status:             FlightStatus.UNKNOWN
                            });
    }


    /*************************************************************/
    /*                  Modifier methods                         */
    /*************************************************************/

    modifier _is_authorized_call() {
        require( msg.sender == _contract_owner, "Possible hack - called by unowned contract" );
        _;
    }

    modifier _is_airline_call() {       
        require( tx.origin == _airline, "Changes can be made by airline account only" );        
        _;
    }

    modifier _can_airline_claim() {
		require( _flight_data.status != FlightStatus.UNKNOWN, "Airline can claim funds only after updating flight status" );
       	_;
    }

    modifier _can_make_claim( uint now_ ) {
          require( now_ > _get_flight_time() + (24*60*60), "The claim for funds can be made only after 24 hours of flight departure." ) ;
		_;
    }    

    
    /*************************************************************/
    /*                  Public API's required for Airline        */
    /*************************************************************/

    // The status can be updated multiple times within 24 hours of the flight start time.
    function update_status( uint8 status_, uint delayed_time_, uint now_ ) public _is_authorized_call _is_airline_call returns( bool ) {       
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

        return true;
    }

    function claim_ticket_price( uint pnr_, uint now_ ) _is_authorized_call _is_airline_call  _can_airline_claim() _can_make_claim(now_) public returns( bool ) {
        Ticket ticket = _tickets[pnr_];

        require( _is_ticket_exist( ticket ), "The ticket does not exist for the PNR." );

        uint8 refund_percentage = _get_refund_percentage();

        return ticket.claimed_by_airline(refund_percentage);
    }


    /*************************************************************/
    /*                  Public API's required for Customers      */
    /*************************************************************/

    // Seats booking by customer in the flight.
    function book_seats( uint8 requested_seat_count_ ) public payable _is_authorized_call returns( uint ) {
        require( requested_seat_count_ > 0, "Please provide a valid number of seat count." );

        if ( _flight_data.available_seats < requested_seat_count_ ) {
            revert( "The number of seats requested are not available in the flight." );
        }

        uint ticket_price = requested_seat_count_ * _flight_data.price_per_seat;
        require( msg.value == ticket_price, "Please pay with the exact amount." );

        _flight_data.booked_seats    += requested_seat_count_;
        _flight_data.available_seats -= requested_seat_count_;  

        // Generate a new PNR:
        g_pnr += 1;  

         // Make a new Ticket contract:    
        Ticket ticket =  new Ticket{value:msg.value}( _airline, _flight_data.departure_time, requested_seat_count_, ticket_price, g_pnr );        // Book the seats:          
        _tickets[g_pnr] = ticket;        
        
        return g_pnr;
    }

    // Cancelling a booked ticket by customer in the flight.
    function cancel_ticket( uint pnr_, uint now_ ) public _is_authorized_call {
        Ticket ticket = _tickets[pnr_];
        require( _is_ticket_exist( ticket ), "The ticket does not exist for the PNR." );

        uint8 penalty_percentage = _get_penalty_percentage( now_ );
        ticket.cancel_by_customer( penalty_percentage );
        
        uint8 _booked_seats = ticket.get_booked_seats();
        _flight_data.booked_seats -= _booked_seats;
        _flight_data.available_seats += _booked_seats;
    }

    // Claim refund after 24 hours of the flight start time by customer.
    function claim_refund(  uint pnr_, uint now_ ) _is_authorized_call _can_make_claim( now_ ) public {
        //uint  now_ = block.timestamp; // Current timestamp
        Ticket ticket = _tickets[pnr_];        
        require( _is_ticket_exist( ticket ), "The ticket does not exist for the PNR." );

        uint8 refund_percentage = _get_refund_percentage();
        ticket.claimed_by_customer( refund_percentage );
    }

    function get_customer_ticket( uint pnr_ ) _is_authorized_call public view returns( uint, uint8, uint, uint ) { 
        Ticket ticket = _tickets[pnr_];
        require( _is_ticket_exist( ticket ), "The ticket does not exist for the PNR." );

        return ticket._ticket_data();
    }
 

    /*************************************************************/
    /*      Private methods required for the public API's        */
    /*************************************************************/

    function _is_ticket_exist( Ticket ticket_ ) private pure returns( bool ) {        
        bytes32 data = bytes32( abi.encodePacked( ticket_ ) );
        bytes32 NULL = bytes32( uint(0) );

        return data != NULL;
    }

    function _get_flight_time() private view returns ( uint ) {
        uint flight_time ;

        if ( _flight_data.status == FlightStatus.ONTIME || _flight_data.status == FlightStatus.CANCELLED ) {
			flight_time = _flight_data.departure_time;          
        } 
        else if ( _flight_data.status == FlightStatus.DELAYED ) {
		   flight_time = _flight_data.delayed_time;  
		}	

        return flight_time;   
    }

    // Penalty policy of the flight.
    function _get_penalty_percentage( uint now_ ) view private returns( uint8 ) {
        RefundRules _refund = RefundRules(address(_refund_rules));

        uint8 penalty_percentage = _refund.get_penalty_percentage(now_, _flight_data.departure_time);

        return penalty_percentage;
    }
	
    // Refund policy of the flight.
    function _get_refund_percentage() view private returns( uint8 ) {
        /* 
            Decide the refund percentage on customer:
            1. If the flight status is not updated and it's still UNKNOWN, then refund with 100%.
            2. If the flight status is CANCELLED, that means the full refund has already been made to 
               the customer and the ticket contract's status is already set to SETTLED.
            3. If the flight status is DELAYED, then refund with 20%.
            4. If the flight status is ONTIME, then refund with 0%.
        */
         
        uint8 refund_percentage;
    
        if( _flight_data.status == FlightStatus.UNKNOWN ) { // The airline did not update the status.
            refund_percentage = 100;
        } 
        else if( _flight_data.status == FlightStatus.CANCELLED ) { // The airline has updated the status to CANCELLED.
            refund_percentage = 100;
        } 
        else if( _flight_data.status == FlightStatus.DELAYED ) { // The airline has updated the status to DELAYED with updated start time.
            // Define multiple delay penalties in favour of the customer.
            RefundRules _refund = RefundRules( _refund_rules );
            refund_percentage = _refund.get_refund_percentage( _flight_data.delayed_time, _flight_data.departure_time );         
        } 
        else if( _flight_data.status == FlightStatus.ONTIME ) { // The airline has updated the status to ONTIME.
            refund_percentage = 0;
        }

        return refund_percentage;
    }
	

    /*************************************************************/
    /*               Common public APIs                          */
    /*************************************************************/

	/*
    function get_flight_owner() public view returns( address ) {
        return _airline;
    }

    function get_balance() public view returns (uint) {
        return address(this).balance;
    }

    function get_flight_data() public view returns( FlightData memory ) {
        return _flight_data;
    }
	*/
}

interface RefundRules{
    function get_penalty_percentage( uint cancel_time, uint departure_time ) pure external returns( uint8 ) ;
    function get_refund_percentage(uint departure_time, uint scheduled_time) pure external returns( uint8 ) ;
}