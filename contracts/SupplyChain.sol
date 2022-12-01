// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

import "./Products.sol";
import "./Users.sol";


contract SupplyChain is Users, Products {
    // on the deployment of a contract the manufacturer is created by itself
    constructor(string memory name_, string memory email_) {
        Types.UserDetails memory mn_ = Types.UserDetails({
            role: Types.UserRole.Manufacturer,
            id_: msg.sender,
            name: name_,
            email: email_
        });
        add(mn_);
    }

    // get all the products that exist in the inventory
    function getAllProducts() public view returns (Types.Product[] memory) {
        return products;
    }

    // to get only the products linked to my account
    function getMyProducts() public view returns (Types.Product[] memory) {
        return getUserProducts();
    }

   // get a specific product
    function getSingleProduct(string memory barcodeId_)
        public
        view
        returns (Types.Product memory, Types.ProductHistory memory)
    {
        return getSpecificProduct(barcodeId_);
    }

    // only manufacturer can add the product
    function addProduct(Types.Product memory product_, uint256 currentTime_)
        public
        onlyManufacturer
    {
        addAProduct(product_, currentTime_);
    }

    // the logged in user can sell the product
    function sellProduct(
        address partyId_,
        string memory barcodeId_,
        uint256 currentTime_
    ) public {
        require(isPartyExists(partyId_), "Party not found");
        Types.UserDetails memory party_ = users[partyId_];
        sell(partyId_, barcodeId_, party_, currentTime_);
    }

    // to add a user under the reign of the logged in user
    function addParty(Types.UserDetails memory user_) public {
        addparty(user_, msg.sender);
    }
    
    function checkDeliv(string memory barcodeId_, uint256 currentTime_) public {
        checkdelivery(barcodeId_,currentTime_,getPartyDetails(msg.sender));
    }

    function rec(string memory barcodeId_, uint256 currentTime_)public{
        recieve(barcodeId_,currentTime_,getPartyDetails(msg.sender));
    }
    // get a specific user detail
    function getUserDetails(address id_)
        public
        view
        returns (Types.UserDetails memory)
    {
        return getPartyDetails(id_);
    }

    // to get the detail of the logged in user
    function getMyDetails() public view returns (Types.UserDetails memory) {
        return getPartyDetails(msg.sender);
    }

    // to get all the user under the logged in user reign
    function getMyUsersList()
        public
        view
        returns (Types.UserDetails[] memory usersList_)
    {
        return getMyPartyList(msg.sender);
    }
}