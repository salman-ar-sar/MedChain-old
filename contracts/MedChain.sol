pragma solidity ^0.4.17;

contract DoctorFactory {
    address[] doctors;
    
    function createDoctor() public {
        address newDoctor = new Doctor(msg.sender);
        doctors.push(newDoctor);
    }
    
    function getDoctors() public view returns (address[] memory) {
        return doctors;
    }
}

contract Doctor {
    address public ownerDoctor;
    address[] patients;
    
    constructor (address _owner) public {
        ownerDoctor = _owner;
    }
    
    function createPatient(address _patient) public {
        address newPatient = new Patient(_patient);
        patients.push(newPatient);
    }
    
    function getPatients() public view returns (address[] memory) {
        return patients;
    }
}

contract PatienFactory {
    address[] patients;
    
    function createPatient() public {
        address newPatient = new Patient(msg.sender);
        patients.push(newPatient);
    }
    
    function getPatients() public view returns (address[] memory) {
        return patients;
    }
}

contract Patient {
    struct Record {
        uint recordID;
        address creatorDoc;
        string description;
        mapping (address => bool) canView;
    }
    
    address public ownerPatient;
    Record[] records;
    mapping (uint => uint) indices;
    uint noOfRecords;
    mapping (address => bool) canCreate;
    // Record record;
    
    constructor (address _owner) public {
        ownerPatient = _owner;
        noOfRecords = 0;
    }
    
    modifier restricted() {
        require(msg.sender == ownerPatient);
        _;
    }
    
    function createRecord(uint _id, string memory _desc) public {
        require(canCreate[msg.sender], "You dont have permission!");
        Record memory record = Record({
            recordID: _id,
            creatorDoc: msg.sender,
            description: _desc
        });
        // record.canView[msg.sender] = true;
        records.push(record); 
        indices[_id] = noOfRecords;
        noOfRecords++;
    }
    
    function giveViewPerm(uint _id, address _doc) public restricted {
        Record storage record = records[indices[_id]];
        require(!record.canView[msg.sender], "You already have permission");
        
        record.canView[_doc] = true;
    }
    
    function revokeViewPerm(uint _id, address _doc) public restricted {
        Record storage record = records[indices[_id]];
        
        record.canView[_doc] = false;
    }
    
    function giveCreatePerm(address _doc) public restricted {
        require(!canCreate[_doc], "You dont have permission");
        
        canCreate[_doc] = true;
    }
    
    function revokeCreatePerm(address _doc) public restricted {
        canCreate[_doc] = false;
    }
    
    function viewRecord(uint _id) public view returns(uint, address, string memory){
        Record storage record = records[indices[_id]];
        require(record.canView[msg.sender] || msg.sender == record.creatorDoc, "You dont have permission");
        return (record.recordID, record.creatorDoc, record.description);
    }
}
