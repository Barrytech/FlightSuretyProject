//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    mapping(address => bool) private authorizeCaller;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(  ) public{
        contractOwner = msg.sender;
        authorizeCaller[contractOwner] = true;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational(){
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner(){
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    //added caller to be auth
    modifier requireCallerAuthorized(){
        require(authorizeCaller[msg.sender] == true, "This caller is not authorized"); 
        _;
    }

    modifier requireSufficientBalance(address account, uint256 amount){
        require(amount <= passengerBalance[account], "There isn't enought money for this transaction");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus( bool mode) external requireContractOwner {
        operational = mode;
        return operational;
    }

    function authorizeCaller(address _address) external requireIsOperational requireContractOwner{
        authorizeCaller[_address] = true;
    }

    function unauthorizeCaller(address _address) external requireContractOwner requireIsOperational {
        delete authorizeCaller[_address];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(address airlineAddress) external requireIsOperational requireCallerAuthorized returns(bool) {
        airlines[airlineAddress].status = AirlineStatus.Registred;
        registeredAirlineCount++;
        return airlines[airlineAddress].status = AirlineStatus.Registred;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy(address passengerAddress, uint256 insuranceAmount, bytes32 flightKey, address airlineAddress ) requireIsOperational requireCallerAuthorized external payable{
        airlines[airlineAddress].underwrittenAmount.add(insuranceAmount);
        flightInsurance[flightKey].purchaseAmount[passengerAddress] = insuranceAmount;
        flightInsurance[flightKey].passengers.push[passengerAddress];
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 flightKey, address airlineAddress) requireIsOperational requireCallerAuthorized  external {
        require(!flightInsurance[flightKey].isPaidOut, "This insurance has already been paid out");
        for(uint i = 0; i < flightInsurance[flightKey].passengers.length; i++){
            address passengerAddress = flightInsurance[flightKey].passengers[i];
            uint256 purchasedAmount = flightInsurance[flightKey].purchasedAmount[passengerAddress];
            uint256 payoutAmount = purchasedAmount.nul(3).div(2);
            passengerBalance[passengerAddress] = passengerBalance[passengerAddress].add(payoutAmount);
            airlines[airlineAddress].funds.sub(payoutAmount);
        }
        flightInsurance[flightKey].isPaidOut = true;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address insured, uint256 amount) external requireIsOperational requireCallerAuthorized requireSufficientBalance(insured, amount) {
        passengerBalance[insured] = passengerBalance[insured].sub(amount);
        insured.transfert(amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund (address airlineAddress, uint256 fundingAmount) requireIsOperational requireIsOperational public payable return (uint256){
        airlines[airlineAddress].funds = airlines[airlineAddress].fund.add(fundingAmount);
        airlines[airlineAddress].status = AirlineStatus.Funded;
        return airlines[airlineAddress].funds;
    }

    function getFlightKey ( address airline, string memory flight, uint256 timestamp) pureinternal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external  payable {
        fund();
    }


}

