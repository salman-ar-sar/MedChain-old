pragma solidity ^0.5.0;

contract record {
    
    string ownerPatient;
    string creatorDoctor;
    string description;
    uint recordId;

    constructor(string memory _patient, string memory _doctor, uint _recordId, string memory _desc) public{
        ownerPatient = _patient;
        recordId = _recordId;
        creatorDoctor = _doctor;
        description = _desc;
    }
    
    function getRecord() public view returns(string memory, string memory, uint, string memory){
        return (ownerPatient, creatorDoctor, recordId, description);
    }
}