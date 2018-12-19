pragma solidity ^0.4.23;


library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    if(b > a) {
        return 0;
    } else {
        uint256 c = a - b;
        return c;
    }
    
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract LECToken {
    function mint(address _playerAddress) external payable returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

contract Oracle {
    function creatRandomNumber(address _address) external returns (uint256);
}

contract DividendFund {
    function playerFrom(string inviterCode, address sender) external returns (bool);
    function showInvitationCodeOf(string _code) external view returns (address);
    function showInviter(address _addr) external view returns(address);
    function awardFund() external payable;
}

contract TronBlock {
    using SafeMath for uint256;

    
    modifier gameIsActive {
        require(gamePaused != true);
		_;
    }
    
    /*
     * checks only owner address is calling
    */
    modifier onlyOwner {
         require(msg.sender == owner);
         _;
    }
    
    modifier isHuman() {
        address _addr = msg.sender;
        require(_addr == tx.origin);

        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
    
    
    modifier betIsValid(uint _betSize, uint8 _playerNumber, uint _height) {
        require(rewardOfVictory(_betSize, _playerNumber, _height).sub(_betSize) <= maxProfit && _betSize >= minBet && _playerNumber >= minNumber && _playerNumber <= maxNumber);
		_;
    }    
    
    
    /*
     * game vars
    */ 
    uint constant public maxProfitDivisor = 1000000;
    //Return the base
    uint constant public scaleDivisor = 10000;    
    uint8 constant public maxNumber = 100; 
    uint8 constant public minNumber = 20;
	bool public gamePaused = true;
    address public owner;

    
    //Percentage return
    uint public houseEdge = 9851;   
    
    uint public bancorEdge = 10;
    uint public fundEdge = 90;
    //Single-pass income cap
    uint public maxProfit;   
    //Base pool reward ratio
    uint public maxProfitAsPercentOfHouse = 1000;                    
    uint public minBet; 


    // uint256 public playerTotalWin = 0;
    
    LECToken public myToken;
    Oracle public numberOracle;
    DividendFund public myFund;
    
    mapping (address => uint) public playerHeight;
    // mapping (address => uint) public playerInput;
    
    /*
     * events
    */
    event DiceResult(
        address indexed player,
        uint256 randNum,
        uint256 chooseNum,
        uint256 height,
        uint256 invest,
        uint256 award,
        uint256 tokenAmount
        );
    
    event PlayerWithdraw(
        address indexed player,
        uint256 award,
        uint256 height
        );
    
    
        
    event LogOwnerTransfer(
        address sendTo, 
        uint256 amount); 
    
    constructor() public {
        owner = msg.sender;
        minBet = 10000000;
    }
    
    
    // The first time player start the game, height have to be 0
    // Convert the invitation code to byte32 and pass it in.
    // web3.fromAscii(code, 32)
    function playerBuild(uint8 rollUnder) public 
        payable
        gameIsActive
        isHuman
        betIsValid(msg.value, rollUnder, 0)
	{    

	    //1% to bankor
	    uint256 token = myToken.mint.value(msg.value * bancorEdge / scaleDivisor)(msg.sender);
	    myFund.awardFund.value(msg.value * fundEdge / scaleDivisor)();

        uint256 randomNum = numberOracle.creatRandomNumber(msg.sender);
        if (randomNum < rollUnder) {
            uint winNum = rewardOfVictory(msg.value, rollUnder, playerHeight[msg.sender]);
            msg.sender.transfer(winNum);
            if(rollUnder < maxNumber) {
                playerHeight[msg.sender] = playerHeight[msg.sender].add(1);
            }
            // playerTotalWin = playerTotalWin.add(winNum);
            emit DiceResult(msg.sender, randomNum, rollUnder, playerHeight[msg.sender], msg.value, winNum, token); 
        } else {
            playerHeight[msg.sender] = 0;
            emit DiceResult(msg.sender, randomNum, rollUnder, 0, msg.value, 0, token);
        }
        // playerInput[msg.sender] = playerInput[msg.sender].add(msg.value);
    }
    
    function playerBuildWithCode(uint8 rollUnder, string code) public 
        payable
        gameIsActive
        isHuman
        betIsValid(msg.value, rollUnder, 0)
	{    
        if(myFund.showInvitationCodeOf(code) != 0x0) {
            myFund.playerFrom(code, msg.sender);
        }
	    //0.1% to bankor
	    uint256 token = myToken.mint.value(msg.value * bancorEdge / scaleDivisor)(msg.sender);
	    myFund.awardFund.value(msg.value * fundEdge / scaleDivisor)();

        uint256 randomNum = numberOracle.creatRandomNumber(msg.sender);
        if (randomNum < rollUnder) {
            uint winNum = rewardOfVictory(msg.value, rollUnder, playerHeight[msg.sender]);
            msg.sender.transfer(winNum);
            if(rollUnder < maxNumber) {
                playerHeight[msg.sender] = playerHeight[msg.sender].add(1);
            }
            // playerTotalWin = playerTotalWin.add(winNum);
            emit DiceResult(msg.sender, randomNum, rollUnder, playerHeight[msg.sender], msg.value, winNum, token); 
        } else {
            playerHeight[msg.sender] = 0;
            emit DiceResult(msg.sender, randomNum, rollUnder, 0, msg.value, 0, token);
        }
    }
    
    //Returns the reward you can receive if you win
    function rewardOfVictory(uint _betSize, uint8 _betNum, uint _height) public view returns(uint) {
        uint a = _height;
        if(a > 10) {
            a = 10;
        }
        return _betSize * 100 * (houseEdge + a*2) / (scaleDivisor * _betNum);
    }
    
    function showInviter(address _addr) public view returns(address) {
        return myFund.showInviter(_addr);
    }

    /*
    * internal function
    * sets max profit
    */
    function setMaxProfit() internal {
        maxProfit = (address(this).balance * maxProfitAsPercentOfHouse)/maxProfitDivisor;  
    }      

    /*
    * owner/treasury address only functions
    */
    function () public
        payable
    {
        setMaxProfit();
    }
    
    /* only owner address can change Token address */
    function changeTokenAddress(address _newAddress) public onlyOwner {
        myToken = LECToken(_newAddress);
    }
    
    /* only owner address can change oracle address */
    function changeOracleAddress(address _newAddress) public onlyOwner {
        numberOracle = Oracle(_newAddress);
    }
    
    function changeFundAddress(address _newAddress) public onlyOwner {
        myFund = DividendFund(_newAddress);
    }

    /* only owner adjust contract balance variable (only used for max profit calc) */
    function ownerUpdateContractBalance() public payable
		onlyOwner
    {        
       setMaxProfit();
    }    
    
    /* only owner address can set bancorEdge */
    function ownerSetBancorEdge(uint newEdge) public 
		onlyOwner
    {
        bancorEdge = newEdge;
    }
    
    /* only owner address can set fundEdge */
    function ownerSetFundEdge(uint newEdge) public 
		onlyOwner
    {
        fundEdge = newEdge;
    }
    
    /* only owner address can set houseEdge */
    function ownerSetHouseEdge(uint newHouseEdge) public 
		onlyOwner
    {
        houseEdge = newHouseEdge;
    }

    /* only owner address can set maxProfitAsPercentOfHouse */
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public 
		onlyOwner
    {
        /* restrict each bet to a maximum profit of 1% contractBalance */
        require(newMaxProfitAsPercent <= 10000);
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

    /* only owner address can set minBet */
    function ownerSetMinBet(uint newMinimumBet) public 
		onlyOwner
    {
        minBet = newMinimumBet;
    }       

    /* only owner address can transfer ether */
    function ownerTransfer(address sendTo, uint amount) public 
		onlyOwner
    {        
        sendTo.transfer(amount);
        emit LogOwnerTransfer(sendTo, amount); 
    }

    /* only owner address can set emergency pause #1 */
    function ownerPauseGame(bool newStatus) public 
		onlyOwner
    {
		gamePaused = newStatus;
    }


    /* only owner address can set owner address */
    function ownerChangeOwner(address newOwner) public 
		onlyOwner
	{
        owner = newOwner;
    }

    /* only owner address can suicide - emergency */
    function ownerkill() public 
		onlyOwner
	{
	    owner.transfer(address(this).balance);
		selfdestruct(owner);
	}    
}









