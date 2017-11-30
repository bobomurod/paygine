
//fiatcontract верси 1
//задача данного контракта:
//Предоставить возможность для внешнего скрипта сохранять актуальную цену эфира в блокчейне
//для дальнейшего использованния в контрактах

pragma solidity ^0.4.18;

contract MyFiatContract{
    address creator;    //адресс создатетля контракта 
    
    uint usd;           //здесь будем хранить актуальную цену эфириума в центах
    event NewPrice(uint ExPrice, uint CurrentPrice);                    //ивент для будущих использований 
    function creatorChange(address newCreator) {                //можно менять создателя
        require(msg.sender == creator);
        require(creator != address(0));
        creator = newCreator;
    }
    function MyFiatContract() {
        creator = msg.sender;                       //только создатель может менять цену эфира 
    }

    function UpdatePrice(uint newUSD)  {            // та самая функция которая берет переменную из вне и записывает в блокейн, для дальнейшего доступа с других контрактов
        require(msg.sender == creator);             //проверка отправителя на создателя
        NewPrice(usd, newUSD);
        usd = newUSD;
    }
    
    function GetPrice() constant returns (uint) {           //функция чтобы другие контракты могли забирать цену с этого контракта (чтение в блокчейне бесплатно)
        return usd;
    }
}

