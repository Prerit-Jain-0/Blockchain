// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.8.11;


contract Ticket {
    address private _airline;
    address private _customer;
    address private _owner_contract;

    enum TicketStatus { 
                        BOOKED, 
                        CLAIMED_BY_CUSTOMER, 
                        CLAIMED_BY_AIRLINE, 
                        SETTLED
                    }

    struct TicketData {
        uint    flight_time;
        uint8   booked_seats;
        uint    total_price;
        uint    pnr;
	}

    TicketStatus _status;
    TicketData  public  _ticket_data;
                  
    constructor( address airline_, uint flight_time_, uint8 seat_count_, uint total_seat_, uint pnr_ ) payable {
        _airline  = airline_;
        _customer = tx.origin;
        _owner_contract = msg.sender;
        _status   = TicketStatus.BOOKED;

        _ticket_data  = TicketData({
                                flight_time:  flight_time_,
                                booked_seats: seat_count_,
                                total_price:  total_seat_,
                                pnr:          pnr_
                            });
    }


    /*************************************************************/
    /*                  Modifier methods                         */
    /*************************************************************/

    modifier _is_authorized_call() {
        require( msg.sender == _owner_contract, "Possible hack - called by unowned contract" );
        _;
    }

    modifier _is_customer_call() {
        require( tx.origin == _customer, "Ticket can be changed only by ticket customer" );
        _;
    }
   
    modifier _can_claim_funds() {
        require( _status != TicketStatus.SETTLED, "Ticket is already settled" );
        _;
    }


    /*************************************************************/
    /*                  Public API's required for Airline        */
    /*************************************************************/
	
    function claimed_by_airline( uint8 refund_percentage_ ) _is_authorized_call _can_claim_funds public payable returns( bool ) {
        require( _status != TicketStatus.CLAIMED_BY_AIRLINE,"Airline has already claimed their funds" );

        uint total_value = address(this).balance;
        uint airline_part;
        TicketStatus new_status ;

        if( _status != TicketStatus.CLAIMED_BY_CUSTOMER ) {
            uint customer_part = _calculate_customer_claim( refund_percentage_ );
            airline_part = total_value - customer_part;
            new_status = TicketStatus.CLAIMED_BY_AIRLINE;
        }else{
            airline_part = total_value;
            new_status = TicketStatus.SETTLED;
        }

        _payment_to_airline( airline_part );
        _status = new_status;

        return true;
    }


    /*************************************************************/
    /*                  Public API's required for Customers      */
    /*************************************************************/

    function cancel_by_customer( uint8 penalty_percentage_ ) _is_authorized_call _is_customer_call public {
        require( _status == TicketStatus.BOOKED, "The ticket can only be cancelled if it's in BOOKED state." );

        uint airline_part  = ( address(this).balance * penalty_percentage_ ) / 100;
        uint customer_part = address(this).balance - airline_part;

        _payment_to_customer( customer_part );
        _status = TicketStatus.CLAIMED_BY_CUSTOMER;     
    }

    function claimed_by_customer( uint8 refund_percentage_ ) _is_authorized_call _is_customer_call _can_claim_funds public returns( bool ){
        require( _status != TicketStatus.CLAIMED_BY_CUSTOMER,"Customer has already claimed their funds" );

        uint total_value = address(this).balance;
        uint customer_part;
        TicketStatus new_status ;

        if( _status != TicketStatus.CLAIMED_BY_AIRLINE ) {
            customer_part = _calculate_customer_claim( refund_percentage_ );            
            new_status = TicketStatus.CLAIMED_BY_CUSTOMER;
        } else {
            customer_part = total_value;
            new_status = TicketStatus.SETTLED;
        }

        _payment_to_customer( customer_part );
        _status = new_status;

        return true;        
    }


    /*************************************************************/
    /*      Private methods required for the public API's        */
    /*************************************************************/

    function _payment_to_customer( uint amount_ ) private {
        payable(_customer).transfer( amount_ );
    }

    function _payment_to_airline( uint amount_ ) private {
        payable(_airline).transfer( amount_ );
    }

    function _calculate_customer_claim( uint8 refund_perc_ ) public view returns( uint ){
        uint customer_part = ( address(this).balance * refund_perc_ ) / 100;
        return customer_part;
    }

    
    /*************************************************************/
    /*               Common public APIs                          */
    /*************************************************************/
    function  get_booked_seats() public view returns ( uint8 ) {
       return _ticket_data.booked_seats;
    }
    
    /*
    function get_ticket_owner() public view returns( address ) {
        return _customer;
    }

    function get_balance() public view returns (uint) {
        return address(this).balance;
    }
    */
}