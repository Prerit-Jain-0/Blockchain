// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.8.11;


contract RefundRules{

     // Penalty policy of the flight.
    function get_penalty_percentage( uint cancel_time, uint departure_time )  pure external returns( uint8 ) {
        /* 
            Define multiple cancellation penalties in favour of the airline:
            If customer cancels before 24 hours of flight departure time, then refund with 40% penalty.
            If customer cancels after 24 hours but before 2 hours of flight departure time, then refund with 60% penalty.
            If customer cancels after that time, then 100% penalty will be applied.
        */

        uint8 penalty_percentage = 0;

        //uint  cancel_time = block.timestamp; // Current timestamp
        uint time_diff =  departure_time - cancel_time;

        if ( time_diff > (24*60*60) ) {       // Cancelling before 24 hours of flight departure time.
            penalty_percentage = 40;

        } else if ( time_diff > (2*60*60) ) { // Cancelling after 24 hours but before "2 hours of flight start time".
            penalty_percentage = 60;

        } else {                              // Cancelling after "2 hours before the flight start time".
            penalty_percentage = 100;
        }

        return penalty_percentage;
    }
	
    // Refund policy of the flight.
    function get_refund_percentage( uint departure_time, uint scheduled_time ) pure external returns( uint8 ) {
        /* 
            Define multiple delay penalties in favour of the customer if the flight status is DELAYED
            1. If delay is less than 1 hour, refund 10%.
            2. If delay is between 1 hours to 5 hours, refund 50%.
            3. If delay is more than 5 hours, refund 100%.
        */
       
            // Define multiple delay penalties in favour of the customer.
            uint time_delayed = departure_time - scheduled_time;
            uint8 refund_percentage;

            if ( time_delayed < (1*60*60) ) { // Less than 1 hour delay.
                refund_percentage = 10;

            } else if ( time_delayed < (5*60*60) ) { // Delay time is between 1 hours to 5 hours.
                refund_percentage = 50;

            } else { // Delay is more than 5 hours.
                refund_percentage = 100; // Full refund.
            }

        return refund_percentage;
    }

}