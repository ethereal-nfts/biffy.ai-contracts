pragma solidity 0.5.17;


contract SenderApprovals {

    mapping (address => mapping (address => bool)) public operatorApprovals;

    function setOperatorApproval(address operator, bool approved) external {
        require(operator != msg.sender, "Sender cannot be their own operator.");
        operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedOrSelf(address spender) public view returns (bool) {
        return (tx.origin == spender && (msg.sender == spender || operatorApprovals[spender][msg.sender]));
    }
}
