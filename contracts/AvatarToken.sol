//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC404} from "./ERC404.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract AvatarToken is ERC404 {
    uint256 public constant MINT_PRICE = 0.02048 ether;
    //4000 for first minters/400 allocate to team
    uint256 public constant LEFT_COUNT = 5556;

    function setNameSymbol(
        string memory _name,
        string memory _symbol
    ) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }

    function mint() external payable nonReentrant whenNotPaused {
        uint256 unit = _getUnit();
        require(
            (totalSupply/unit) <= (maxCount - LEFT_COUNT),
            "No mint capacity left"
        );
        

        uint256 price = MINT_PRICE;

        if (balanceOfNFT(msg.sender) >= 5) {
            revert("Only less thant or equal to 5  can be mint");
        }
        if (msg.value < price) {
            revert("Insufficient funds sent for minting.");
        }
        _mint(msg.sender);
        balanceOf[msg.sender] += unit;
        totalSupply += unit;

        //set to project owner
        if ((totalSupply / unit) % 10 == 9) {
            _mint(owner());
            balanceOf[owner()] += unit;
            totalSupply += unit;
        }
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function mintBatch(uint256 numTokens) external payable nonReentrant whenNotPaused {
        uint256 unit = _getUnit();
        require(
            numTokens > 0 && numTokens <= 5,
            "Number of tokens must be greater than 0 and less than or equal to 5"
        );
        require(
            totalSupply/unit + numTokens <=
                (maxCount - LEFT_COUNT),
            "exceeds maximum supply"
        );

        uint256 totalPrice = 0;
        uint256 price = MINT_PRICE;
        for (uint256 i = 0; i < numTokens; i++) {
            totalPrice += price;
        }
        require(
            msg.value >= totalPrice,
            "Insufficient funds sent for minting."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _mint(msg.sender);
            balanceOf[msg.sender] += unit;
            totalSupply += unit;
            if ((totalSupply / unit) % 10 == 9 && totalSupply / unit < maxCount) {
                _mint(owner());
                balanceOf[owner()] += unit;
                totalSupply += unit;
            }
        }
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function airdropBatch(address[] calldata recipients) external onlyOwner {
        uint256 unit = _getUnit();
        require(
            totalSupply/unit + recipients.length <= maxCount,
            "Exceeds maximum supply"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i]);
            balanceOf[recipients[i]] += unit;
            totalSupply += unit;            
        }
    }
    function airdropToOwner(uint256 numTokens) external onlyOwner {
        uint256 unit = _getUnit();
        require(
            totalSupply/unit + numTokens <= maxCount,
            "Exceeds maximum supply"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _mint(owner());
            balanceOf[owner()] += unit;
            totalSupply += unit;
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            uint256 balance = address(this).balance;
            payable(owner()).transfer(balance);
        } else {
            IERC20(token).transfer(
                owner(),
                IERC20(token).balanceOf(address(this))
            );
        }
    }
}