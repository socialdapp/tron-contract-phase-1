// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract IDA {
    address public vendorAddress; //vendor

    // getParents
    function distributePayout(
        IERC20 _payoutToken,
        address _child,
        uint256 totalPayoutAmount,
        address _child2
    ) internal {
        uint256 amount = (totalPayoutAmount * (100)) / 1000;

        // _payoutToken.approve(vendorAddress, totalPayoutAmount);

        // s_tokenPayment.transferFrom(msg.sender, vendorAddress, _price);
        _payoutToken.transferFrom(
            _child,
            vendorAddress,
            totalPayoutAmount - amount // 20-2 -> 18
        );
    }

    function distributePayoutNormal(
        IERC20 _payoutToken,
        address _child,
        uint256 totalPayoutAmount,
        address _child2
    ) internal {
        uint256 amount = (totalPayoutAmount * (100)) / 1000;

        _payoutToken.transferFrom(_child, _child2, amount);
        _payoutToken.transferFrom(
            _child,
            vendorAddress,
            totalPayoutAmount - amount
        );
    }

    function setVendor(address _address) external {
        vendorAddress = _address;
    }
}

contract IDATesting is IDA {
    IERC20 public s_tokenPayment;

    // constructor() {}

    function setTokenPayment(IERC20 _address) external {
        s_tokenPayment = _address;
    }

    function mintProduct(uint256 _price, address _child2) external {
        // dangerous behaviour, for hackthon purpose
        // s_tokenPayment.approve(address(this), _price);
        // s_tokenPayment.approve(msg.sender, _price);

        // vendor address ready
        uint256 allowance = s_tokenPayment.allowance(msg.sender, address(this));
        uint256 buyerBalance = s_tokenPayment.balanceOf(msg.sender);

        require(buyerBalance > _price, "not enough balance");
        require(allowance >= _price, "need more allowance");

        // s_tokenPayment.transferFrom(msg.sender, vendorAddress, _price);
        distributePayout(s_tokenPayment, msg.sender, _price, _child2);
    }

    function mintProduct2(uint256 _price, address _child2) external {
        // dangerous behaviour, for hackthon purpose
        // s_tokenPayment.approve(address(this), _price);
        // s_tokenPayment.approve(msg.sender, _price);

        uint256 allowance = s_tokenPayment.allowance(msg.sender, address(this));
        uint256 buyerBalance = s_tokenPayment.balanceOf(msg.sender);

        require(buyerBalance > _price, "not enough balance");
        require(allowance >= _price, "need more allowance");

        // s_tokenPayment.transferFrom(msg.sender, vendorAddress, _price);
        distributePayoutNormal(s_tokenPayment, msg.sender, _price, _child2);
    }

    function requestDollar(uint256 _price) external {
        s_tokenPayment.mint(msg.sender, _price);
    }

    function viewProduct(uint256 _price)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            bool
        )
    {
        uint256 allowance = s_tokenPayment.allowance(msg.sender, address(this));
        uint256 buyerBalance = s_tokenPayment.balanceOf(msg.sender);

        // require(buyerBalance > _price, "not enough balance");
        // require(_price < allowance, "need more allowance");

        return (
            _price < allowance,
            allowance,
            buyerBalance,
            buyerBalance > _price
        );
    }
}
