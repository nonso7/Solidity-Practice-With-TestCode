// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract BankAccount {
        event Deposit(
        address indexed user,
        uint256 indexed accountId,
        uint256 value,
        uint256 timestamp
    );
    event WithdrawRequested(
        address indexed user,
        uint256 indexed accountId,
        uint256 indexed withdrawId,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(uint256 indexed withdrawId, uint256 timestamp);
    event AccountCreated(
        address[] owners,
        uint256 indexed id,
        uint256 timestamp
    );

    struct WithdrawRequest {
        address user;// user who requested a withdraw
        uint256 amount;
        uint256 approvals; // no of approvals{approval == number owners}
        mapping(address => bool) ownersApproved; // which owner has approved, to be approved only once 
        bool approved;
    }

    struct Account {
        address[] owners;
        uint256 balance;
        mapping(uint256 => WithdrawRequest) withdrawRequests; //keep track of withdrawal request
    }

    mapping(uint256 => Account) accounts;
    mapping(address => uint256[]) userAccounts;

    uint256 nextAccountId;
    uint256 nextWithdrawId;

    modifier onlyOwner(uint accountId) {
        bool owner;
        for (uint i; i < accounts[accountId].owners.length; i++) {
            if(accounts[accountId].owners[i] == msg.sender) {
                owner = true;
            }
        }
        require(owner, "Only owner can execute this function");
        _;
    }

    modifier validOwners(address[] calldata owners) {
        require(owners.length + 1 <= 4, "Maximum of 4 owners per account");
        for(uint id; id < owners.length; id++) {
            for(uint j = id + 1; j < owners.length; j++){
                if(owners[id] == owners[j]) {
                    revert("no Duplicate owner");
                }
            }
        }
        _;
    }

       modifier canApprove(uint256 accountId, uint256 withdrawId) {
        require(
            !accounts[accountId].withdrawRequests[withdrawId].approved,
            "this request is already approved"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].user != msg.sender,
            "you cannot approve this request"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].user != address(0),
            "this request does not exist"
        );
        require(
            !accounts[accountId].withdrawRequests[withdrawId].ownersApproved[
                msg.sender
            ],
            "you have already approved this request"
        );
        _;
    }

    modifier canWithdraw(uint256 accountId, uint256 withdrawId) {
        require(
            accounts[accountId].withdrawRequests[withdrawId].user == msg.sender,
            "you did not create this request"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].approved,
            "this request is not approved"
        );
        _;
    }

    modifier sufficientBalance(uint amount, uint accountId){
        require(accounts[accountId].balance >= amount, "Insuffience balance");
        _;
    }

    function deposit(uint accountId) external payable onlyOwner(accountId){
        accounts[accountId].balance += msg.value;
    }

    function createAccount(address[] calldata otherOwners) external validOwners(otherOwners){
        address[] memory owners = new address[](otherOwners.length + 1);// turning the dynamic user array to a static array
        //The new keyword in the following code: is used to dynamically allocate memory for an array. Here's why and how it works:
        owners[otherOwners.length] = msg.sender; //Adds the caller of the function (msg.sender) to the last position in the owners array.

        //array.length - 1: Refers to the index of the last element in the array
        //array[length -1]: Refers to the value of the last element in the array

        uint256 id = nextAccountId;

        for(uint256 idx; idx < owners.length; id++) {
            if(idx < owners.length - 1) {//For all indices except the last one (id < owners.length - 1), the function copies otherOwners into the owners array.
                owners[idx] = otherOwners[id];
            }

            if(userAccounts[owners[idx]].length > 2) {
                revert("Maximum number of owners reached");

            }

            userAccounts[owners[idx]].push(id);

            accounts[id].owners = owners;
            nextAccountId++;
            emit AccountCreated(owners, id, block.timestamp);
        }

    }


    function requestWithdrawal(uint accountId, uint amount) external 
        onlyOwner(accountId) 
        sufficientBalance(amount, accountId){
        uint256 id = nextWithdrawId;
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[id];
        request.user = msg.sender;
        request.amount = amount;
        nextWithdrawId++;
        emit WithdrawRequested(
            msg.sender,
            accountId, 
            id, 
            amount,
            block.timestamp);
    }

    function approveWithdrawal(uint accountId, uint withdrawId) external 
        onlyOwner(accountId)
        canApprove(accountId, withdrawId)
        {
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[withdrawId];
        request.approvals++;
        request.ownersApproved[msg.sender] = true;

        if (request.approvals == accounts[accountId].owners.length - 1) {
            request.approved = true;
        }
    }

    function withdrawal(uint accountId, uint withdrawalId) external  {
        uint256 amount = accounts[accountId].withdrawRequests[withdrawalId].amount;
        require(accounts[accountId].balance >= amount, "insufficient balance");

        accounts[accountId].balance -= amount;
        delete accounts[accountId].withdrawRequests[withdrawalId];

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
         require(sent, "failed to send");

        emit Withdraw(withdrawalId, block.timestamp);    
    }

    function getBalance(uint256 accountId) public view returns(uint256){
        return accounts[accountId].balance;
    }

    function getOwners(uint accountId) public view returns(address[] memory) {
        return accounts[accountId].owners;
    }

    function getApproval(uint accountId, uint withdrawId) public view returns(uint256) {
        return accounts[accountId].withdrawRequests[withdrawId].approvals;
    }

    function getAccounts()public view returns(uint256[] memory) {
        return userAccounts[msg.sender];
    }
}