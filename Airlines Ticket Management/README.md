Blockchain Based Ticket Management

Introduction
You’ll be helping Eagle Airlines develop a unique blockchain based ticket management system to entice users with transparency, and automated refunds and delay penalties.

 

You’ll be setting up a private Ethereum blockchain and developing a base ticketing contract. This would allow immediate refund in case of cancellations and predefined penalty payment in case of delays.

 

You are expected to complete at least the basic requirements. You can choose to pick one or more advanced features as well. The exact scope should be defined by your group and then validated by your mentor and the Great Learning team.

 

Basic Requirements
 

As the base platform, you’ll be creating a private Ethereum blockchain, using geth, in the cloud. You can have the nodes running on EC2 machines directly (on different ports) or you can run each node in a docker container. Use Clique (Proof of Authority) for faster block creations.

 

You’ll be developing a base contract code, in Solidity, which will be deployed every time a ticket is bought by a customer from Eagle Airlines. 

 

The airlines will deploy the contract with customer address and simulated dummy flight details (flight number, seat category, flight datetime, etc.). The customer will then call a specific function to transfer the ticket money to the contract and receive a confirmation id and flight details in response.

 

The features required in the smart contract are:


The customer should be able to trigger a cancellation anytime till 2 hours before the flight start time. This should refund money to the customer minus the percentage penalty predefined in the contract by the airlines. The penalty amount should be automatically sent to the airline account.
Any cancellation triggered by the airline before or after departure time should result in a complete amount refund to the customer.
The airline should update the status of the flight within 24 hours of the flight start time. It can be on-time start, cancelled or delayed.
24 hours after the flight departure time, the customer can trigger a claim function to demand a refund.
They should get a complete refund in case of cancellation by the airline. 
In case of a delay, they should get a predefined percentage amount, and the rest should be sent to the airline.
If the airline hasn’t updated the status within 24 hours of the flight departure time, and a customer claim is made, it should be treated as an airline cancellation case by the contract.
Randomness and call based simulation of various features like normal flights, cancellation by the airline, cancellation by the customer, and delayed flights.

The features and systems essential for the system to function are:


Private blockchain creation using Geth and related tools
Create blockchain nodes in AWS either directly in EC2 machines with different ports, or in dockerized containers
Choose Clique (Proof of Authority)
Create at least 3 nodes with 2 airline accounts allowed to be block creators (sealers/miners) and at least 4 customer accounts
Base contract in Solidity covering all the functionalities defined above
Demonstrate contract behaviour via geth command line tool or via Remix connected to your private blockchain

Advanced Features

Add support for multiple cancellation penalties in favour of the airline, and delay penalties in favour of the customer, based on various time ranges in the contract.

Instead of simulating the flight data and flight behaviour, you can use an Oracle to get actual flight information and act accordingly. This would require
Using a flight api like https://aviationstack.com/documentation or https://opensky-network.org/apidoc/index.html
Setting up chainlink to receive data through that api and into your smart contract - https://docs.chain.link/docs/request-and-receive-data/
Defining your smart contract with actual upcoming flight information and using the Oracle to update status

Using Geth-based EVM allows for controls of who can modify the state but doesn’t prevent the information from being visible to anyone on the blockchain. Hyperledger Besu is an Ethereum based modified EVM with support for private transactions. Enhance your solution by using Besu nodes instead of Geth, and mark all transactions as private, only visible to the airline account(s) and the customer account.
