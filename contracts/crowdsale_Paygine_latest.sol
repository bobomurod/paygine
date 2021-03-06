pragma solidity ^0.4.18;

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

interface Paygine {									//подключаем токен

		function balanceOf(address who) public constant returns (uint256);
  	function transfer(address to, uint256 value) public returns (bool);
  	function allowance(address owner, address spender) public constant returns (uint256);
  	function transferFrom(address from, address to, uint256 value) public returns (bool);
  	function approve(address spender, uint256 value) public returns (bool);

}

interface MyFiatContract {					//подключаем контракт оракул 
    function GetPrice() constant returns (uint);
}

contract Ownable {
    
  address public owner;							//овнер=управляющий контрактом
  MyFiatContract public MyPrice;
 
  
  function Ownable() {
    owner = msg.sender;
  }
 
  
  modifier onlyOwner() {					//модификатор позволяющий ограничивать управление контрактом со стороны третих лиц 
    require(msg.sender == owner);
    _;
  }
 
  function transferOwnership(address newOwner) onlyOwner {							//Функция для смены "управляющего" контрактом
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}

contract CrowdsalePaygine is Ownable {
	//mapping(address => uint256) purchases;  // сколько токенов купили на данный адрес 

	event Debag (string message);																										//пачка ивентов для дальнейших нужд
	event TokenPurchased(address purchaser, uint256 value, uint amount);
	event ContractPaused(uint time);
	event ContractPauseOff(uint time);
	event ContractEnded(uint time);
	

    
  	using SafeMath for uint;
    
  	address fundAddress;   			//тот кому идут эфиры (creator of contract)
 
  	
 
  	Paygine token = Paygine(0x388ace50bfeba98e15af4ab1d754bda7823e34c0);					//адресс контракта нашего токена (незабудьте поменять)
 
  	uint priceInCents;		

  	uint256 ETHUSD;		// how many USD cents in 1 ETH 

		uint256 etherHardPrice;					// Установленная цена эфира на случай взлома Оракул-контракта 

  	uint256 public totalPurchased;  // total tokens purchased on crowdsale PUBLIC!!!

  	uint256 thisPhaseMaxPurchase; // max tokens to crowdsale

  	bool public pause;

  	bool public end;

    uint32 public bonusPercent = 0;

		function setMaxPurchase(uint256 maxPurchaseForThisPhase) onlyOwner {
				thisPhaseMaxPurchase = maxPurchaseForThisPhase * 10 ** 18;
		}		//в начале это 3000000 а потом 86250000

    function bonusChange(uint32 newBonusPercent) onlyOwner {			//Можно менять процент бонуса (указывается в процентах)
				require(newBonusPercent < 40);														//Исключаем возможность ставить бонус больше 40 процент
        bonusPercent = newBonusPercent;
    }

		function setEtherHardPrice(uint256 hardPrice) onlyOwner {
				etherHardPrice = hardPrice;
		}

		function fundAddressChange(address newFundAddress) onlyOwner {			//Можно менять адресс фонда куда все деньги поступают
				fundAddress = newFundAddress;
		}

    function changeOracul(address newOracle) onlyOwner {						//Можно менять адресс оракула 
      	MyPrice = MyFiatContract(newOracle);
    }
 
  	function CrowdsalePaygine() {
      MyPrice = MyFiatContract(0xa7e80008e7316de144c6c61e3343600a96be674c);    //захардкоженный адрес оракул-контракта, нужно сделать функцию смены адреса чтобы не быть привязанным к одному адресу
	  	ETHUSD = MyPrice.GetPrice();
			etherHardPrice = 40000;																									 //Устанавливаем хард-цену эфира в 400баксов на момент инициализации контракта
	    fundAddress = msg.sender;
	    priceInCents = 100;  	// price in USD cents for 1 token  
	    
	    //purchaseCap = 89250000 * 10 ** 18;  // 89250000 tokens to one address 
	    totalPurchased = 0;
			thisPhaseMaxPurchase = 3000000 * 10 ** 18;
	    // maxPurchase = 89250000 * 10 ** 18; // 89250000 tokens sales on crowdsale 
	    Debag("crowdsale inits");
	    pause = false;
	    end = false;
  	}

  	
 
  	modifier saleIsOn() {
    	
    	require(totalPurchased <= thisPhaseMaxPurchase);
      require(pause == false);
      require(end == false);
    	_;
  	}

  	modifier isPaused() {																//модификатор проверки "на паузе или нет" 
  		require(pause == true);
  		_;
  	}

  	function setPauseOn() onlyOwner saleIsOn {					//поставить на паузу
  		pause = true;
  		ContractPaused(now);
  	}
	
  	function setPauseOff() onlyOwner isPaused {					//Отмена паузы
  		pause = false;
  		ContractPauseOff(now);
  	}
  	
  	function endCrowdsale(uint code) onlyOwner {    //остановка (завершение) краудсейла
      uint password = 1234561;											//пароль для завершения
			// bytes32 hashedPassword = "4b4bdbe81084e2023f39335fabe54ce0a0d3a30d1803015122e421fddf0f7b7b";		//пароль [1234561]  по sha256
      // require(hashedPassword == keccak256(code));						//проверили пароль, если все ок, то завершаем краудсейл
			require(password == code);
  		end = true;
  		ContractEnded(now);
			token.transfer(owner, token.balanceOf(address(this)));    	//Последняя поправка: вывод оставшихся токенов на баланс управляющего после завершения краудсейла
  	}

		function withdrawTokens(uint quantity) onlyOwner {						//Отдельная функция для вывода N количество токенов с баланса crowdsale-контракта
			token.transfer(fundAddress, quantity);
		}


  	/*
		посылая 1 эфир инвестор получает (цена 1ETH*100) центов = по умолчанию делим на 100 (цена одного токена один доллар)
  	*/
 
  	function createTokens() saleIsOn payable {
			ETHUSD = MyPrice.GetPrice();																//присвоение переменной ETHUSD цены взятого со стороннего контракта
			require(ETHUSD >= etherHardPrice);													//проверка цены эфира на искуственного понижения
	    uint tokens = msg.value.mul(ETHUSD).div(priceInCents);  		// вычисление токенов за присланный эфир
      uint bonusTokens = tokens.mul(bonusPercent).div(100);
	    uint tokensWithBonus = tokens.add(bonusTokens);
	 
	    require(token.balanceOf(this) >= tokensWithBonus);					//проверка токен-баланса контракта для совершение операции
	    require(thisPhaseMaxPurchase >= totalPurchased + tokensWithBonus);		//Количество тотал-проданных+токены с бонусами которых надо сейчас отдать должны быть меньше или равно макскапу данного периода

	    TokenPurchased(msg.sender, msg.value, tokensWithBonus); 		 // ивент покупки токенов (покупатель, цена в эфирах, кол-во токенов)
	    
	    totalPurchased = totalPurchased.add(tokensWithBonus);				// суммировать все купленные токены
	    fundAddress.transfer(msg.value);														// перевод средств фонду 
	    token.transfer(msg.sender, tokensWithBonus);								// контракт со своего баланса переводит токены инвестору 
  	}
 
  function() external payable {
    createTokens();
  }
    
}