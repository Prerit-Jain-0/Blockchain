
Please find presentation slides (pptx) with below name in the project root folder:

	< path-to-Blockchain_Smita Srivastava_Final Submissin >\Blockchain Airline ticket booking.pptx
	


Please find the smart contract codebase at below path from the project root folder:

	< path-to-Blockchain_Smita Srivastava_Final Submissin >\Contract\contracts
	

Please refer the powerpoint presentation (pptx) from 10th slide to understand on how to use the smart contract. Please find a few helpful inputs to test the smart contract at below path as well from the project root folder:

	< path-to-Blockchain_Smita Srivastava_Final Submissin >\Contract\use_cases.txt


Please refer below path to find the instructions, genesis file and screenshots for setting up the private blockchain using Hyperledger BESU:
	< path-to-Blockchain_Smita Srivastava_Final Submissin >\private_blockchain_setup\


Please find Web-UI related instructions below and refer below path to find related code/screenshots:
	< path-to-Blockchain_Smita Srivastava_Final Submissin >\Web_UI\
	
For UI Code refer - UI.zip

	Steps to check UI code running 
	
	1. Metamask must be installed as chrome plugin and configured with accounts imported.
	2. Change the following config in truffle_config.js 
			host: "127.0.0.1",
      			port: 7545,
      			network_id: "*" // Match any network id
	3.Change chain URL with respective deployment in app_admin_server.js,replce IP address, sample IP is demoed implementation 
		App.web3Provider = new Web3.providers.HttpProvider('http://3.84.100.30:8547');
	4. By default code deployment migration is added as follows, do not change if there is no change in public api contract file name.
		this will deploy ticket manger which is used in code to access contract api.
		var TicketManager = artifacts.require("TicketManager");
		module.exports = function(deployer) {
		  deployer.deploy(TicketManager);
		};

	5. follow steps to run and test application
	
		-- install node js 
		
		-- npm install -g truffle
		
		for first time contract deployment 
		
		go to src folder and make sure contracts folder is one level up and run following commands 
	
		-- truffle compile
		-- truffle migrate 
		
		if you change any of the function in ticket manager please use following command, this will redploy the ticket manager, there are other ways to override the contract but following --reset will be safest way to deploy 
		
		-- truffle migrate --reset
		
	6. now run following command to test app and after successful start visit http://localhost:3000/admin.html
	admin page will allow you to load flights and cancel loaded flight in next tab, please refer image for more details
	
		-- npm run dev


	Load flights to contract sample screen after running app 
![Alt text](Web_UI\book_flights.png?raw=true "Load flights")

![Alt text](Web_UI\cancel_flight.png?raw=true "Load flights")
