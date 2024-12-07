// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Insurance {
    address public insurer; // Address of the insurer (contract owner)  

    enum PolicyStatus { Active, Expired, Claimed } 

    struct Policy {
        address policyholder;
        uint256 premium;
        uint256 coverageAmount;
        uint256 expiryTime;
        PolicyStatus status;   
    }

    struct Claim {
        uint256 claimAmount;
        string reason;
        bool isApproved;
    }

    mapping(uint256 => Policy) public policies;
    mapping(uint256 => Claim) public claims;
    uint256 public policyCounter;

    event PolicyIssued(uint256 policyId, address policyholder, uint256 premium, uint256 coverageAmount, uint256 expiryTime);
    event PremiumPaid(uint256 policyId, address policyholder, uint256 amount);
    event ClaimSubmitted(uint256 policyId, uint256 claimAmount, string reason);
    event ClaimApproved(uint256 policyId, uint256 claimAmount);
    event ClaimPaid(uint256 policyId, address policyholder, uint256 claimAmount);

    modifier onlyInsurer() {
        require(msg.sender == insurer, "Only the insurer can perform this action");
        _;
    }

    modifier onlyPolicyholder(uint256 policyId) {
        require(policies[policyId].policyholder == msg.sender, "Only the policyholder can perform this action");
        _;
    }

    constructor() {
        insurer = msg.sender; // The creator of the contract is the insurer
    }

    function issuePolicy(address policyholder, uint256 premium, uint256 coverageAmount, uint256 duration) external onlyInsurer {
        require(policyholder != address(0), "Invalid policyholder address");

        policyCounter++;
        policies[policyCounter] = Policy(
            policyholder,
            premium,
            coverageAmount,
            block.timestamp + duration,
            PolicyStatus.Active
        );

        emit PolicyIssued(policyCounter, policyholder, premium, coverageAmount, block.timestamp + duration);
    }

    function payPremium(uint256 policyId) external payable onlyPolicyholder(policyId) {
        Policy storage policy = policies[policyId];
        require(policy.status == PolicyStatus.Active, "Policy is not active");
        require(block.timestamp < policy.expiryTime, "Policy has expired");
        require(msg.value == policy.premium, "Incorrect premium amount");

        emit PremiumPaid(policyId, msg.sender, msg.value);
    }

    function submitClaim(uint256 policyId, uint256 claimAmount, string memory reason) external onlyPolicyholder(policyId) {
        Policy storage policy = policies[policyId];
        require(policy.status == PolicyStatus.Active, "Policy is not active");
        require(block.timestamp < policy.expiryTime, "Policy has expired");

        claims[policyId] = Claim(claimAmount, reason, false);
        emit ClaimSubmitted(policyId, claimAmount, reason);
    }

function getContractBalance() public view returns (uint256) {
    return address(this).balance;
}




    function approveClaim(uint256 policyId) external onlyInsurer {
        Claim storage claim = claims[policyId];
        Policy storage policy = policies[policyId];
        require(policy.status == PolicyStatus.Active, "Policy is not active");
        require(!claim.isApproved, "Claim is already approved");

        claim.isApproved = true;
        emit ClaimApproved(policyId, claim.claimAmount);
    }

   function payClaim(uint256 policyId) external onlyInsurer {
    Claim storage claim = claims[policyId];
    Policy storage policy = policies[policyId];
    require(claim.isApproved, "Claim is not approved");
    require(policy.status == PolicyStatus.Active, "Policy is not active");
    require(address(this).balance >= claim.claimAmount, "Insufficient contract balance");

    payable(policy.policyholder).transfer(claim.claimAmount);
    policy.status = PolicyStatus.Claimed;

    emit ClaimPaid(policyId, policy.policyholder, claim.claimAmount);
}


    // Fallback function to accept payments
    receive() external payable {}
}
