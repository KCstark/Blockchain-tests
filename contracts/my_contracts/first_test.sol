// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract first_test{
    //define parent
    address owner;

    event logChildFunding(address add,uint amount,uint contractBalance);
    
    constructor(){
        //msg is a global variable that is automatically available inside all functions. 
        //It contains properties like msg.sender, msg.value, and msg.data, which provide information about the transaction that triggered
        owner=msg.sender;
    }

    //define child
    struct child{
        address payable  childAddress;
        uint amount;
        string firstName;
        string lastName;
        uint releaseDate;
        bool isWithdrawable;
    }

    child[] public children;
    //add child to contract
    function addChild(address payable _childAddress, uint _amount, string memory _firstName, string memory _lastName, uint _releaseDate,bool _isWithdrawable) public onlyOwner{
        children.push(child(_childAddress, _amount, _firstName, _lastName, _releaseDate, _isWithdrawable));
    }  

    function balanceOf() public view returns(uint){
        return address(this).balance; //this is the current contract address)
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"you arenot allowed");
        _;
    }

    //deposit funds to contract, specifically to  child's account
    function deposit(address walletAddress) payable public onlyOwner{
        addToChildsBalance(walletAddress);
    }

    function addToChildsBalance(address walletAddress) private onlyOwner{
        for( uint i=0;i<children.length;i++){
            if(children[i].childAddress==walletAddress){
                children[i].amount=children[i].amount+msg.value;
                emit logChildFunding(walletAddress, msg.value, balanceOf());
            }
        }
    }
    
    function getIndex(address wallestAddress) private view returns (uint){
        for( uint i=0;i<children.length;i++){
            if(children[i].childAddress==wallestAddress){
                return i;
            }
        }
        return 9999;//cant send -1 coz uint
    }

    //child check if able to withdraw
    function canWithdraw(address walletAddress) public returns(bool){
        uint index=getIndex(walletAddress);
        if(index==9999){
            return false;
        }
        require(index!=9999,"Wrong child not in block");
        if(children[index].isWithdrawable){
            return true;
        }
        //check if current block timestamp is greater than release date
        require(block.timestamp>=children[index].releaseDate,"you cant withdraw yet");
        if(block.timestamp>= children[index].releaseDate){
            children[index].isWithdrawable=true;
            return true;
        }
        return false;
    }

    //withtdraw money
    function withdraw(address payable  walletAddress) payable public{
        uint index=getIndex(walletAddress);
        if(index==9999){
            // console.log("addres not in children"); //not a child
            return;
        }
        require(children[index].childAddress==msg.sender,"Police is coming");
        require(canWithdraw(walletAddress),"You cant withdraw yet");
        children[index].childAddress.transfer(children[index].amount);
        
    }
}