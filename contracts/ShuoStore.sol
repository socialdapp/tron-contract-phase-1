// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//
interface IProductFactory {
    function mint(address to, uint256 productId) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function createCollection(
        uint256 productId,
        string memory uri,
        string memory category
    ) external;
}
interface ISubscriptionNFT {
    function mint(address to) external;
    function balanceOf(address owner) external view returns (uint256 balance);

}
interface IProfileToken {
    function getParent(address _child) external view returns (address);
}

interface ISocialPoints {
    function issuePoints(address to, uint256 points) external;
}

error ErrorPricing(address nftAddress, uint256 price);
error BalanceToLow(uint256 buyerBalance);
error InvalidLength();


contract ShuoStore is Ownable {
    struct StoreItem {
        uint256 price;
        uint256 socialPoints;
        string uri;
        string category;
        address nftAddress;
    }

    mapping(uint256 => StoreItem) public s_storeItems;
    mapping(uint256 => uint256) public s_productArrayIndexes;

    uint256 public s_subscriptionProductID = 99;
    uint256 public s_maxParentTree;
    uint256[] public s_products;
    uint256[] public s_uints;

    // address
    ISubscriptionNFT public s_subscriptionsContract;
    IProfileToken public s_profileContract;
    ISocialPoints public s_socialPoints;
    address public s_vendorAddress;
    IERC20 public s_tokenPayment;
    IERC20 public s_fakeUSD;

    event ItemBought(address buyer, address nftAddress, uint256 price);
    event CreatedProduct(
        uint256 productId,
        uint256 price,
        uint256 socialPoints,
        string uri,
        string category,
        address nftAddress
    );
    event Distributed(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    constructor() {
        // s_subscriptionProductID =
        // s_tokenPayment = 
        // s_fakeUSD =
        // s_subscriptionsContract =
        // s_profileContract =
        // s_vendorAddress =
        // s_maxParentTree
        // s_uints[]
    }


    // ------ OWNER
    function setSubscriptionAddress(ISubscriptionNFT _address) onlyOwner external{
        s_subscriptionsContract = _address;
    }
    function setProfileTokenAddress(IProfileToken _address) onlyOwner external{
        s_profileContract = _address;
    }
    function setSocialPoints(ISocialPoints _address) onlyOwner external{
        s_socialPoints = _address;
    }
    function setVendorAddress(address _address) onlyOwner external{
        s_vendorAddress = _address;
    }
    function setTokenPayment(IERC20 _address) onlyOwner external{
        s_tokenPayment = _address;
    }
    function setFakeUSD(IERC20 _address) onlyOwner external{
        s_fakeUSD = _address;
    }

  
    function setDistributionUnits( uint256 _maxTree, uint256[] memory _units) onlyOwner external  {
        if (_units.length != _maxTree) { revert InvalidLength(); }

        s_maxParentTree = _maxTree;
        s_uints = _units;
    }


    function listingProduct(
        uint256 _productId,
        uint256 _price,
        uint256 _socialPoints,
        string memory _uri,
        string memory _category,
        address _nftAddress
    ) external onlyOwner {
        if(_productId != s_subscriptionProductID){
            IProductFactory(_nftAddress).createCollection(
                _productId,
                _uri,
                _category
            );
        }
        s_storeItems[_productId] = StoreItem(
            _price,
            _socialPoints,
            _uri,
            _category,
            _nftAddress
        );
        s_products.push(_productId);
        s_productArrayIndexes[_productId] = s_products.length - 1;

        emit CreatedProduct(
            _productId,
            _price,
            _socialPoints,
            _uri,
            _category,
            _nftAddress
        );
    }

    function removeListedProduct(uint256 _productId) onlyOwner external{

    }

    // INTERNAL ---
     function distributeParents(
        address _child,
        uint256 _totalPayment
    ) internal {
        address[] memory parentsChain = _getParentsChain(_child);
        uint256 distributed;

        for (uint256 i = 0; i < s_maxParentTree; i++) {
            if (parentsChain[i] == address(0)) continue;
            if (!_isSubscribed(parentsChain[i])) continue;

            uint256 amount = (_totalPayment * (s_uints[i])) / 1000;

            s_tokenPayment.transferFrom(_child, parentsChain[i], amount);
            distributed += amount;

            emit Distributed(_child, parentsChain[i], amount);
        }

        s_tokenPayment.transferFrom(
            _child,
            s_vendorAddress,
            _totalPayment - distributed
        );
    }

    function _isSubscribed(address _user) internal view returns (bool) {
        return  s_subscriptionsContract.balanceOf(_user) != 0;
    }

    function _getParentsChain(address _child)
        internal view
        returns (address[] memory parentsChain)
    {
        parentsChain = new address[](s_maxParentTree);
        address currentParent = _child;
        for (uint256 i = 0; i < s_maxParentTree; i++) {
            currentParent = s_profileContract.getParent(currentParent);
            parentsChain[i] = currentParent;
        }
    }

    // ------ PUBLIC
    // MINT SUBSCRIPTION first time on buy product
    // on FE -> check balance -> approve
    function purchaseProduct(uint256 _productId) external  {
        StoreItem memory item = s_storeItems[_productId];

        require(item.price != 0, "Product price is missing");
        require(
            item.nftAddress != address(0),
            "Product address is missing"
        );

        // prepare pay with ERC20
        uint256 allowance = s_tokenPayment.allowance(msg.sender, address(this));
        uint256 buyerBalance = s_tokenPayment.balanceOf(msg.sender);

        if (item.price > buyerBalance || item.price >= allowance) {
            revert ErrorPricing(item.nftAddress, item.price);
        }


        // distribute to parents
        distributeParents(msg.sender, item.price);

        // mint product & subscription
        if (_productId != s_subscriptionProductID) {
            // if first time, give SUBS-NFT : hack-thon demo feature
            if(IProductFactory(item.nftAddress).balanceOf(msg.sender) == 0) {
                // todo: boundary not duplicate?
                // ISubscriptionNFT(item.nftAddress).balanceOf(msg.sender) == 0
                s_subscriptionsContract.mint(msg.sender);
            }

            IProductFactory(item.nftAddress).mint(msg.sender, _productId);
        } else {
            // mint subscription
            // address of SUBSCRIPTION NFT
            s_subscriptionsContract.mint(msg.sender);
        }

        s_socialPoints.issuePoints(msg.sender, item.socialPoints);
      
        emit ItemBought(msg.sender, item.nftAddress, item.price);
    }

    function testPoints(uint points)external{
       s_socialPoints.issuePoints(msg.sender, points);
    }

    function testSubscribe()external{
        s_subscriptionsContract.mint(msg.sender);
    }


    function getProductPrice(uint256 _productId)
        external
        view
        returns (uint256)
    {
        return s_storeItems[_productId].price;
    }
   function getStoreItem(uint256 _productId)
        external
        view
        returns (StoreItem memory)
    {
        return s_storeItems[_productId];
    }
}



// --------------------------------------------

// interface GC, Product, Social, Subscription

// deploy store
// setup contract -> ProductFactory, SocialPoints, Subscription

// setup vendorAddress
// setup s_subscriptionProductID
// setup subs_contract address
// setup profile contract address

// PRODUCTS
// - set subscription product -> with subscriptionNFT address
// LOOT_BOX

// PRODUCTS_NFT -> MINT GIFTCODES
// events

