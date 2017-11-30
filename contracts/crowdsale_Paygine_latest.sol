pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface Paygine {

	function balanceOf(address who) public constant returns (uint256);
  	function transfer(address to, uint256 value) public returns (bool);
  	function allowance(address owner, address spender) public constant returns (uint256);
  	function transferFrom(address from, address to, uint256 value) public returns (bool);
  	function approve(address spender, uint256 value) public returns (bool);

}

interface MyFiatContract {
    function GetPrice() constant returns (uint);
}

contract Ownable {
    
  address public owner;
  MyFiatContract public MyPrice;
 
  
  function Ownable() {
    owner = msg.sender;
  }
 
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}

contract CrowdsalePaygine is Ownable {
	//mapping(address => uint256) purchases;  // сколько токенов купили на данный адрес 

	event Debag (string message);
	event TokenPurchased(address purchaser, uint256 value, uint amount);
	event ContractPaused(uint time);
	event ContractPauseOff(uint time);
	event ContractEnded(uint time);
	//event LowTokensOnContract(uint amount);

    
  	using SafeMath for uint;
    
  	address multisig;   			//тот кому идут эфиры (creator of contract)
 
  	//uint restrictedPercent;		
 
  	//address restricted;
 
  	Paygine token = Paygine(0x388ace50bfeba98e15af4ab1d754bda7823e34c0);
 
  	uint priceInCents;		

  	uint256 ETHUSD;		// how many USD cents in 1 ETH 

  	uint256 public totalPurchased;  // total tokens purchased on crowdsale PUBLIC!!!

  	uint256 maxPurchase; // max tokens to crowdsale

  	bool public pause;
  	bool public end;
    uint32 public bonusPercent = 0;

    function bonusChange(uint32 newBonusPercent) onlyOwner {
        bonusPercent = newBonusPercent;
    }

    function changeOracul(address newOracle) onlyOwner {
      MyPrice = MyFiatContract(newOracle);
    }
 
  	function CrowdsalePaygine() {
      MyPrice = MyFiatContract(0xa7e80008e7316de144c6c61e3343600a96be674c);    //захардкоженный адрес оракул-контракта, нужно сделать функцию смены адреса чтобы не быть привязанным к одному адресу
	  	ETHUSD = MyPrice.GetPrice();
	    multisig = msg.sender;
	    priceInCents = 100;  	// price in USD cents for 1 token  
	    
	    //purchaseCap = 89250000 * 10 ** 18;  // 89250000 tokens to one address 
	    totalPurchased = 0;
	    maxPurchase = 89250000 * 10 ** 18; // 89250000 tokens sales on crowdsale 
	    Debag("crowdsale inits");
	    pause = false;
	    end = false;
  	}

  	// function purchasesOf(address purchaser) public constant returns (uint256 value) {
   //  	return purchases[purchaser];
  	// }
 
  	modifier saleIsOn() {
    	//require(now > start && now < start + period * 1 days);
    	require(totalPurchased <= maxPurchase);
      require(pause == false);
      require(end == false);
    	_;
  	}

  	modifier isPaused() {
  		require(pause == true);
  		_;
  	}

  	function setPauseOn() onlyOwner saleIsOn {
  		pause = true;
  		ContractPaused(now);
  	}
	
  	function setPauseOff() onlyOwner isPaused {
  		pause = false;
  		ContractPauseOff(now);
  	}
  	
  	function endCrowdsale(uint code) onlyOwner {    //остановка (завершение) краудсейла
      uint password = 1234561;											//пароль для завершения
      require(password == code);
  		end = true;
  		ContractEnded(now);
			token.transfer(owner, token.balanceOf(address(this)));    //Последняя поправка: вывод оставшихся токенов на баланс управляющего после завершения краудсейла
  	}
  	/*
		посылая 1 эфир инвестор получает 30000 центов = 30_000 / 100 = 300 токенов
  	*/
 
  	function createTokens() saleIsOn payable {
			ETHUSD = MyPrice.GetPrice();
	    uint tokens = msg.value.mul(ETHUSD).div(priceInCents);  // вычисление токенов за присланный эфир
      uint bonusTokens = tokens.mul(bonusPercent).div(100);
	    uint tokensWithBonus = tokens.add(bonusTokens);
	 
	    require(token.balanceOf(this) >= tokensWithBonus);
	    require(maxPurchase >= totalPurchased + tokensWithBonus);	

	    TokenPurchased(msg.sender, msg.value, tokensWithBonus);  // ивент покупки токенов (покупатель, цена в эфирах, кол-во токенов)
	    
	    totalPurchased = totalPurchased.add(tokensWithBonus);				// суммировать все купленные токены
	    multisig.transfer(msg.value);						// перевод создателю всего эфира 
	    token.transfer(msg.sender, tokensWithBonus);		// контракт с себя переводит токены инвестору
  	}
 
  function() external payable {
    createTokens();
  }
    
}