// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

import "./Types.sol";

// all the user related actions are done here
contract Users {
    mapping(address => Types.UserDetails) internal users;
    mapping(address => Types.UserDetails[]) internal manufacturerSuppliersList;
    mapping(address => Types.UserDetails[]) internal supplierVendorsList;
    mapping(address => Types.UserDetails[]) internal vendorCustomersList;

    event NewUser(string name, string email, Types.UserRole role);
    event LostUser(string name, string email, Types.UserRole role);

    //to add a new user
    function add(Types.UserDetails memory user) internal {
        require(user.id_ != address(0));
        require(!has(user.role, user.id_), "Same user with same role exists");
        users[user.id_] = user;
        emit NewUser(user.name, user.email, user.role);
    }

    // to add a party under the logged in user
    function addparty(Types.UserDetails memory user, address myAccount)
        internal
    {
        require(myAccount != address(0));
        require(user.id_ != address(0));

        if (
            get(myAccount).role == Types.UserRole.Manufacturer &&
            user.role == Types.UserRole.Supplier
        ) {
            // Only manufacturers are allowed to add suppliers
            manufacturerSuppliersList[myAccount].push(user);
            add(user); // To add user to global list
        } else if (
            get(myAccount).role == Types.UserRole.Supplier &&
            user.role == Types.UserRole.Vendor
        ) {
            // Only suppliers are allowed to add vendors
            supplierVendorsList[myAccount].push(user);
            add(user); // To add user to global list
        } else if (
            get(myAccount).role == Types.UserRole.Vendor &&
            user.role == Types.UserRole.Customer
        ) {
            // Only vendors are allowed to add customers
            vendorCustomersList[myAccount].push(user);
            add(user); // To add user to global list
        } else {
            revert("Not valid operation");
        }
    }

    // to get the list of the usres that are linked to the logged in user
    function getMyPartyList(address id_)
        internal
        view
        returns (Types.UserDetails[] memory usersList_)
    {
        require(id_ != address(0), "Id is empty");
        if (get(id_).role == Types.UserRole.Manufacturer) {
            usersList_ = manufacturerSuppliersList[id_];
        } else if (get(id_).role == Types.UserRole.Supplier) {
            usersList_ = supplierVendorsList[id_];
        } else if (get(id_).role == Types.UserRole.Vendor) {
            usersList_ = vendorCustomersList[id_];
        } else {
            // Customer flow is not supported yet
            revert("Not valid operation");
        }
    }

    // to get the details of the users that are linked to the logged in user
    function getPartyDetails(address id_)
        internal
        view
        returns (Types.UserDetails memory)
    {
        require(id_ != address(0));
        require(get(id_).id_ != address(0));
        return get(id_);
    }

    // to get the details of a particular user
    function get(address account)
        internal
        view
        returns (Types.UserDetails memory)
    {
        require(account != address(0));
        return users[account];
    }

    // to remove the specified user
    function remove(Types.UserRole role, address account) internal {
        require(account != address(0));
        require(has(role, account));
        string memory name_ = users[account].name;
        string memory email_ = users[account].email;
        delete users[account];
        emit LostUser(name_, email_, role);
    }

    // Internal Functions

    //to check if the party exists
    function isPartyExists(address account) internal view returns (bool) {
        bool existing_;
        if (account == address(0)) return existing_;
        if (users[account].id_ != address(0)) existing_ = true;
        return existing_;
    }

    // the user with the same role exists or not
    function has(Types.UserRole role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0));
        return (users[account].id_ != address(0) &&
            users[account].role == role);
    }

    // Modifiers

 // to check if the user is the manufacturer or not
    modifier onlyManufacturer() {
        require(msg.sender != address(0), "Sender's address is Empty");
        require(users[msg.sender].id_ != address(0), "User's address is Empty");
        require(
            Types.UserRole(users[msg.sender].role) ==
                Types.UserRole.Manufacturer,
            "Only manufacturer can add"
        );
        _;
    }
}