// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

import "./Types.sol";


contract Products {
    Types.Product[] internal products;
    mapping(string => Types.Product) internal product;
    mapping(address => string[]) internal userLinkedProducts;
    mapping(string => Types.ProductHistory) internal productHistory;

    // List of events

    event NewProduct(
        string name,
        string manufacturerName,
        string scientificName,
        string barcodeId,
        uint256 manDateEpoch,
        uint256 expDateEpoch
    );
    event daysLeft(
        uint256 time
    );
    event ProductOwnershipTransfer(
        string name,
        string manufacturerName,
        string scientificName,
        string barcodeId,
        string buyerName,
        string buyerEmail
    );

    // Contract Methods

   //returns all the products that are owned by the logged in user
    function getUserProducts() internal view returns (Types.Product[] memory) {
        string[] memory ids_ = userLinkedProducts[msg.sender];
        Types.Product[] memory products_ = new Types.Product[](ids_.length);
        for (uint256 i = 0; i < ids_.length; i++) {
            products_[i] = product[ids_[i]];
        }
        return products_;
    }

   //get details of a specific product
    function getSpecificProduct(string memory barcodeId_)
        internal
        view
        returns (Types.Product memory, Types.ProductHistory memory)
    {
        return (product[barcodeId_], productHistory[barcodeId_]);
    }

   // manufacturer can add the product
    function addAProduct(Types.Product memory product_, uint256 currentTime_)
        internal
        productNotExists(product_.barcodeId)
    {
        require(
            product_.manufacturer == msg.sender,
            "You are not the manufacturer"
        );
         if(product_.expDateEpoch<currentTime_){
            transferOwnership(msg.sender,0xc929B634150947a653FbDd36cAb4b10f00EffbBF,product_.barcodeId);// dump center
            revert("Product expired!");
        }//432000000 (5days)
        products.push(product_);
        product[product_.barcodeId] = product_;
        productHistory[product_.barcodeId].manufacturer = Types.UserHistory({
            id_: msg.sender,
            dispdate: currentTime_,
            recdate: currentTime_
        });
        userLinkedProducts[msg.sender].push(product_.barcodeId);
        emit NewProduct(
            product_.name,
            product_.manufacturerName,
            product_.scientificName,
            product_.barcodeId,
            product_.manDateEpoch,
            product_.expDateEpoch
        );
    }

    //logged in user wants to transfer the ownership
    function sell(
        address partyId_,
        string memory barcodeId_,
        Types.UserDetails memory party_,
        uint256 currentTime_
    ) internal productExists(barcodeId_) {
        Types.Product memory product_ = product[barcodeId_];
        if(product_.expDateEpoch<currentTime_){
            transferOwnership(msg.sender,0xc929B634150947a653FbDd36cAb4b10f00EffbBF,barcodeId_);
            revert("Product expired!");
        }
        // Updating product history
        Types.UserHistory memory userHistory_ = Types.UserHistory({
            id_: party_.id_,
            dispdate: currentTime_,
            recdate:0
        });
        if (Types.UserRole(party_.role) == Types.UserRole.Supplier) {
            productHistory[barcodeId_].supplier = userHistory_;
        } else if (Types.UserRole(party_.role) == Types.UserRole.Vendor) {
            productHistory[barcodeId_].vendor = userHistory_;
        } else if (Types.UserRole(party_.role) == Types.UserRole.Customer) {
            productHistory[barcodeId_].customers.push(userHistory_);
        } else {
            
            revert("Invalide role");
        }
        transferOwnership(msg.sender, partyId_, barcodeId_); 


        emit ProductOwnershipTransfer(
            product_.name,
            product_.manufacturerName,
            product_.scientificName,
            product_.barcodeId,
            party_.name,
            party_.email
        );
    }

    //check delivery status and if surpasses the due date then ownership transfer to anonymous

    function checkdelivery(string memory barcodeId_, uint256 currentTime_, Types.UserDetails memory me)internal {
             if (Types.UserRole(me.role) == Types.UserRole.Supplier  &&  productHistory[barcodeId_].supplier.recdate==0 &&((currentTime_- productHistory[barcodeId_].supplier.dispdate)>432000000) ){
            transferOwnership(msg.sender,0x89d811672a22BF893eb1b2D27A393eb354DE04D4 , barcodeId_);
        }
         else if (Types.UserRole(me.role) == Types.UserRole.Vendor && productHistory[barcodeId_].vendor.recdate==0 &&((currentTime_- productHistory[barcodeId_].vendor.dispdate)>432000000) ) {
            transferOwnership(msg.sender,0x89d811672a22BF893eb1b2D27A393eb354DE04D4 , barcodeId_);
        } 
         else {
             emit daysLeft(currentTime_- productHistory[barcodeId_].vendor.dispdate);
        }  
    }

    // update the recdate on recieval
      function recieve(string memory barcodeId_, uint256 currentTime_, Types.UserDetails memory me)internal {
             if (Types.UserRole(me.role) == Types.UserRole.Supplier  &&  productHistory[barcodeId_].supplier.recdate==0 && ((currentTime_- productHistory[barcodeId_].supplier.dispdate)<=432000000) ){
            productHistory[barcodeId_].supplier.recdate=currentTime_;
        }
         else if (Types.UserRole(me.role) == Types.UserRole.Vendor && productHistory[barcodeId_].vendor.recdate==0 && ((currentTime_- productHistory[barcodeId_].vendor.dispdate)<=432000000) ) {
            productHistory[barcodeId_].vendor.recdate=currentTime_;
        } 
    }
    // Modifiers

    //to check if the product exists 
    modifier productExists(string memory id_) {
        require(!compareStrings(product[id_].barcodeId, ""));
        _;
    }
     // to check if a product does not exist
    modifier productNotExists(string memory id_) {
        require(compareStrings(product[id_].barcodeId, ""));
        _;
    }

    // ownership transfer that is internally used here itself
    function transferOwnership(
        address sellerId_,
        address buyerId_,
        string memory productId_
    ) internal {
        userLinkedProducts[buyerId_].push(productId_);
        string[] memory sellerProducts_ = userLinkedProducts[sellerId_];
        uint256 matchIndex_ = (sellerProducts_.length + 1);
        for (uint256 i = 0; i < sellerProducts_.length; i++) {
            if (compareStrings(sellerProducts_[i], productId_)) {
                matchIndex_ = i;
                break;
            }
        }
        assert(matchIndex_ < sellerProducts_.length); 
        if (sellerProducts_.length == 1) {
            delete userLinkedProducts[sellerId_];
        } else {
            userLinkedProducts[sellerId_][matchIndex_] = userLinkedProducts[
                sellerId_
            ][sellerProducts_.length - 1];
            delete userLinkedProducts[sellerId_][sellerProducts_.length - 1];
            userLinkedProducts[sellerId_].pop();
        }
    }

    // to compare two string here internally
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}