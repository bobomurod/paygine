pragma solidity ^0.4.18;

contract MyFiatContract{
    address creator;
    
    uint usd;
    event NewPrice(uint ExPrice, uint CurrentPrice);
    function creatorChange(address newCreator) {
        require(msg.sender == creator);
        require(creator != address(0));
        creator = newCreator;
    }
    function MyFiatContract() {
        creator = msg.sender;
    }

    function UpdatePrice(uint newUSD)  { 
        require(msg.sender == creator);
        NewPrice(usd, newUSD);
        usd = newUSD;
    }
    
    function GetPrice() constant returns (uint) {
        return usd;
    }
}

