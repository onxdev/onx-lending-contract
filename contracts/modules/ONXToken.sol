// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "../libraries/SafeMath.sol";
import "./Configable.sol";

contract ONXSampleToken is Configable {
    using SafeMath for uint256; // implementation of ERC20 interfaces.

    uint256 public totalSupply = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(balanceOf[from] >= value, "ONX: INSUFFICIENT_BALANCE");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) {
            // burn
            totalSupply = totalSupply.sub(value);
        }
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "ONX: INSUFFICIENT_ALLOWANCE");
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function mint(uint256 value) external onlyPlatform {
        balanceOf[msg.sender] = balanceOf[to].add(value);
        totalSupply = totalSupply.add(value);
        emit Transfer(from, to, value);
    }

    function burn(uint256 amount) external onlyPlatform {
        _transfer(msg.sender, address(0));
    }
}
