pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract GiveGet is ERC1155("some uri"), Ownable {
	using SafeMath for uint256;

	uint256 public set;
	uint256 constant public DELIMITOR = 2 ** 255;
	IERC20 public yUSD = IERC20(0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c);
	address public treasury;

	mapping(uint256 => uint256) public funds;
	mapping(uint256 => uint256) public recieveSupply;

	mapping(address => bool) public recurrent;
	mapping(address => bool) public whitelist;
	mapping(uint256 => bool) public grantCheck;

	function setTreasury(address _treasury) external onlyOwner {
		treasury = _treasury;
	}

	function addToRecurrent(address[] calldata _members) external onlyOwner {
		for (uint256 i = 0; i < _members.length ; i++)
			recurrent[_members[i]] = true;
	}

	function removeFromRecurrent(address[] calldata _members) external onlyOwner {
		for (uint256 i = 0; i < _members.length ; i++)
			recurrent[_members[i]] = false;
	}

	function addToWhiteList(address[] calldata _members) external onlyOwner {
		for (uint256 i = 0; i < _members.length ; i++)
			whitelist[_members[i]] = true;
	}

	function removeFromWhiteList(address[] calldata _members) external onlyOwner {
		for (uint256 i = 0; i < _members.length ; i++)
			whitelist[_members[i]] = false;
	}

	/*
	 * Create a new grant round. Will revert if previous round hasn't been funded yet
	 * 
	 * _amount: Amount of $GIVE to mint
	 */
	function mintNewSet(uint256 _amount) external onlyOwner {
		require(grantCheck[set], "Coordinapes: previous grant not supplied");
		set++;
		_mint(msg.sender, set, _amount, "");
	}

	/*
	 * Fund current month allocation from either treasury (if set) or sender
	 * 
	 * _amount: Amount of yUSD to distribute on current grant roune
	 */
	function supplyGrants(uint256 _amount) external onlyOwner {
		if (treasury != address(0))
			yUSD.transferFrom(treasury, address(this), _amount);
		else
			yUSD.transferFrom(msg.sender, address(this), _amount);
		funds[set] = funds[set].add(_amount);
		grantCheck[set] = true;
	}

	/*
	 * Sends $GIVE tokens on a whitelisted member which get converted to $GET tokens
	 * 
	 *     _to: Receiver of $GET
	 * _amount: Amount of $GIVE to burn and $GET to mint
	 */
	function give(address _to, uint256 _amount) external {
		require(_to != msg.sender, "Coordinape: sender cannot be receiver");
		require(whitelist[msg.sender], "Coordinape: sender not whitelisted");
		require(whitelist[_to], "Coordinape: receiver not whitelisted");
		require(!recurrent[_to], "Coordinape: receiver cannot be recurrent");

		_burn(msg.sender, set, _amount);
		_mint(_to, set.add(DELIMITOR), _amount, "");
		recieveSupply[set.add(DELIMITOR)] = recieveSupply[set.add(DELIMITOR)].add(_amount);
	}

	/*
	 * Burn $GET tokens to receive yUSD at the end of each grant rounds
	 * 
	 *     _set: Set from which to collect funds
	 * _amount: Amount of $GET to burn to receive yUSD
	 */
	function receive(uint256 _set, uint256 _amount) external {
		require(whitelist[msg.sender], "Coordinape: sender not whitelisted");
		uint256 _funds = funds[_set];
		require(_funds > 0, "Coordinapes: No funds");
		uint256 supply = recieveSupply[_set.add(DELIMITOR)];
		uint256 grant = _funds.mul(_amount).div(supply);

		_burn(msg.sender, _set + DELIMITOR, _amount);
		funds[_set] = funds.sub(grant);
		recieveSupply[_set.add(DELIMITOR)] = supply.sub(_amount);
		yUSD.transfer(msg.sender, grant);
	}
}