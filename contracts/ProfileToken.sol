// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO:
// - PRIVATE s_tokenPositions, s_childsParent, s_childsParent
// - set boundary for transfer token
// - flexible URI TOKEN ?

// Interface GiftCodes
contract ShuocialProfile is  ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public s_tokenPositions;
    mapping(address => address) public s_childsParent;
    mapping(address => address[]) public s_parentsChild;

    address public s_signerWL;
    string public s_baseURI;
    ERC20 public s_fakeUSD;


    constructor() ERC721("ShuoCIAL Profile", "SHUO") {
        // signerWL =
        // baseURI =
    }
    // ------ MODIFIER
    modifier onlyOnce() {
           require(balanceOf(msg.sender) == 0, "You already had profile token");
        _;
    }
    // ------ OWNER
    function setFakeUSD(IERC20 _address) onlyOwner external{
        s_fakeUSD = _address;
    }
    function setPosition(uint256 _position, uint256 _tokenId)external onlyOwner {
        s_tokenPositions[_tokenId] = _position;
    }

    function setParent(address _child, address _parent) public onlyOwner {
        s_childsParent[_child] = _parent;
    }

    function setChildren(address _parent, address[] memory _children) public onlyOwner {
        s_parentsChild[_parent] = _children;
    }


    // ------ PUBLIC FUNCTIONS

    // mint from whitelist
    function mintByWL(string memory uri) external onlyOnce {
        // TODO: add ecrecover for wl -> require  / modifier
        // --------
        // for hackthon purpose -> free mint

        // --------
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        s_tokenPositions[tokenId] = 1;

        // hack-thon => airdrop fakeUSD
        s_fakeUSD.mint(msg.sender, 2000 * 10**18 );
    }

    // mint from invitation
    function mintByCode(string memory uri, address _addressParent) external onlyOnce {
        // TODO: erecover
        // --
        uint256 parentTokenId = tokenOfOwnerByIndex(_addressParent, 0);
        uint256 parentPosition = s_tokenPositions[parentTokenId];
        require(parentPosition != 0, "Parent position is zero");

        // --> CHECK GIFTCODE CONTRACT
        // --> useGiftcode

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        // increase the position
        s_tokenPositions[tokenId] = parentPosition + 1;
        s_childsParent[msg.sender] = _addressParent;
        s_parentsChild[_addressParent].push(msg.sender);

        // hack-thon => airdrop fakeUSD
        s_fakeUSD.mint(msg.sender, 500 * 10**18 );
    }

    // mint from product
    function mintByProduct() external onlyOnce {
        // TODO:
        // store address -> validate -> mint
    }

    function getPosition(uint256 _tokenId) external view returns (uint256) {
        return s_tokenPositions[_tokenId];
    }

    function getParent(address _child) public view returns (address) {
        if (_child == address(0)) {
            return address(0);
        }
        return s_childsParent[_child];
    }

    function getChilds(address _parent) public view returns (address[] memory) {
        return s_parentsChild[_parent];
    }

    // ------ INTERNAL
     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal  {
        // super._beforeTokenTransfer(from, to, tokenId);
        require(balanceOf(to) == 0, "The target address already has profile token" );

        address _parent = s_childsParent[from];
        address[] memory _children = s_parentsChild[from];
        s_childsParent[to] = _parent;
        s_parentsChild[to] = _children;

        // update parent 
        address[] memory _parentChilds = s_parentsChild[_parent];

        for (uint256 i = 0; i < _parentChilds.length; i++) {
            address current = _parentChilds[i];
            if (current == from) {
                _parentChilds[i] = to;
            }
        }
        s_parentsChild[_parent] = _parentChilds;

        // update parent for children
        for (uint256 i = 0; i < _children.length; i++) {
            s_childsParent[_children[i]] = to;
        }

        delete s_parentsChild[from];
        delete s_childsParent[from];
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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

// ----------------
// deploy, setup tokenPayment, setup vendorAddress (+ setupAddressWLSigner)
// ----------------
// 1. user need to approve contract address in fUSD before executing
// 2.
