// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

    contract Escrow{
        address owner;
        mapping (uint256 => EscrowTxn) public escrowTxn;
        uint256 public escrowTxnCount;

        event EscrowTxnCreated(uint256 id, address depositer, address recipient, uint256 amount, string message);
        event EscrowTxnApproved(uint256 id);
        event EscrowTxnRejected(uint256 id);

        constructor () {
            owner=msg.sender;
        }

        enum Status{
            Pending,
            Approved,
            Rejected
        }

        struct EscrowTxn {
                //id, depositer add, amount blocked,recepient, status
                uint256 id;
                address payable depositer;
                address payable recipient;
                uint256 blockedAmount;
                uint256 timeStamp;
                uint256 completeTimeStamp;
                Status status;
        }

        //deposit by buyerr
        function deposit(address payable  seller) public payable returns (uint256)  {
            require(msg.value>0,"Invalid amount, must be greater than 0");
            require(seller!=address(0),"Invalid address");
            uint256 id = escrowTxnCount++;
            EscrowTxn storage currEsc=escrowTxn[id];
            currEsc.id = id;
            currEsc.depositer = payable (msg.sender);
            currEsc.recipient = seller;
            currEsc.blockedAmount = msg.value;
            currEsc.timeStamp = block.timestamp;
            currEsc.status = Status.Pending;
            currEsc.completeTimeStamp = 0;
            emit EscrowTxnCreated(id, msg.sender,seller , msg.value, "Sending escrow id please keep it safe");
            return id;
        }

        //approve escrow -> pay seller
         function approveEscrow(uint256 id) public {
            EscrowTxn storage currEsc=escrowTxn[id];
            require(currEsc.status==Status.Pending, "This transaction has already processed");
            require(msg.sender==currEsc.depositer, "You are not the depositor, only depositer can approve");
            currEsc.status = Status.Approved;
            currEsc.completeTimeStamp = block.timestamp;
            // payable(currEsc.recipient).transfer(currEsc.blockedAmount);// transfer is deprecated so not using it
            //.call{} is a low level function so need to implement reentrancy safety for this later :)
            //see notes for more details
            (bool success,)=currEsc.recipient.call{value: currEsc.blockedAmount}("");
            require(success, "Transaction Failed, failed to send Ether!");
            emit EscrowTxnApproved(id);
         }

        //cancle escrow -> refund to depositor
        function cancelEscrow(uint256 id) public {
            EscrowTxn storage currEsc=escrowTxn[id];
            require(currEsc.depositer==msg.sender,"You are not the depositor, only depositer can cancel");
            require(currEsc.status==Status.Pending,"This transaction has already processed");
            currEsc.status=Status.Rejected;
            currEsc.completeTimeStamp=block.timestamp;
             //.call{} is a low level function so need to implement reentrancy safety for this later :)
            (bool success,)=currEsc.depositer.call{value: currEsc.blockedAmount}("");
            require(success, "Transaction Failed, failed to refund Ether!");
            emit EscrowTxnRejected(id);
        }
        
    }