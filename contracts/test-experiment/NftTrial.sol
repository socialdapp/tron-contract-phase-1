// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IDA {
    address public vendorAddress = TA6acAExqj8mmBkhL4MVPbSqUiJsG8mWDE; //vendor

    function distributePayout(
        IERC20 _payoutToken,
        address _child,
        uint256 totalPayoutAmount
    ) internal {
        _payoutToken.transferFrom(
            _child,
            vendorAddress,
            totalPayoutAmount * 0.5 // test where the other half goes?
        );
    }
}

contract NftTrial is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, IDA {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IERC20 public s_token;

    constructor() ERC721("Product", "PD") {
        // contract setup ERC20
        s_token = TGjyneVnLavYQGLD22nVxrSjxPnkPfKLZm;
    }

    //function TRON -
    function() external payable {}

    function transferTokenTest(
        address payable toAddress,
        uint256 tokenValue,
        trcToken id
    ) public payable {
        toAddress.transferToken(tokenValue, id);
    }

    function msgTokenValueAndTokenIdTest()
        public
        payable
        returns (trcToken, uint256)
    {
        trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
        return (id, value);
    }

    function getTokenBalanceTest(address accountAddress)
        public
        payable
        returns (uint256)
    {
        trcToken id = 1000001;
        return accountAddress.tokenBalance(id);
    }

    // mintProduct without price?
    function mintProductPay() external {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        distributePayout(s_token, msg.sender, 3333000000000000000000);
    }

    // mintProduct with price
    function mintProduct(uint256 _price) external {
        uint256 allowance = s_token.allowance(msg.sender, address(this));
        uint256 buyerBalance = s_token.balanceOf(msg.sender);

        require(buyerBalance > _price, "not enough balance");
        require(_price < allowance, "need more allowance");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        distributePayout(s_token, msg.sender, _price);
    }

    // test create account and send erc20 - fake USD
    function createAccount() external {
        // require("");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        s_token.transfer(msg.sender, 2222 ether);
    }

    function createAccountMint() external {
        // require("");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        s_token._mint(msg.sender, 2222 ether);
    }

    // function safeMint(address to, string memory uri) public onlyOwner {
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }

    function withdrawToken(address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
