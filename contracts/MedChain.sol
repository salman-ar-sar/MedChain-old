pragma solidity ^0.4.26;

contract UserFactory {
    mapping (address => address) patientsAddress;
    mapping (address => address) doctorsAddress;
    mapping (address => address) public addressPatients;
    mapping (address => address) public addressDoctors;
    
    modifier registered {
        require(doctorsAddress[msg.sender] == 0x0000000000000000000000000000000000000000 && patientsAddress[msg.sender] == 0x0000000000000000000000000000000000000000, "Already registered as doctor or patient");
        _;
    }
    
    function registerPatient() public registered {
        address newPatient = new Patient(msg.sender, false, 0x00);
        patientsAddress[msg.sender] = newPatient;
        addressPatients[newPatient] = msg.sender;
    }
    
    function addPatients(address _pat, address _dep) public {
        patientsAddress[_pat] = _dep;
        addressPatients[_dep] = _pat;
    }
    
    function registerDoctor() public registered {
        address newDoctor = new Doctor(msg.sender);
        // doctors.push(newDoctor);
        doctorsAddress[msg.sender] = newDoctor;
        addressDoctors[newDoctor] = msg.sender;
    }
    
    function loginPatient() public view returns (address) {
        require(patientsAddress[msg.sender] != 0x0000000000000000000000000000000000000000, "Not registered as patient");
        return patientsAddress[msg.sender];
    }
    
    function loginDoctor() public view returns (address) {
        require(doctorsAddress[msg.sender] != 0x0000000000000000000000000000000000000000, "Not registered as doctor");
        return doctorsAddress[msg.sender];
    }
}

contract Doctor {
    address public ownerDoctor;
    UserFactory Ufactory;
    address factory;
    
    constructor (address _owner) public {
        ownerDoctor = _owner;
        factory = msg.sender;
        Ufactory = UserFactory(factory);
    }
    
    modifier restricted() {
        require(msg.sender == ownerDoctor);
        _;
    }
    
    function createPatient(address _patient) public restricted {
        address newPatient = new Patient(_patient, true, ownerDoctor);
        
        Ufactory.addPatients(_patient, newPatient);
    }
}

contract Patient {
    struct Record {
        uint recordID;
        address creatorDoc;
        string description;
        mapping (address => bool) canView;
    }
    
    struct Request {
        uint recordID;
        address viewer;
        bool isView; // false for create
    }
    
    address public ownerPatient;
    Record[] records;
    mapping (uint => uint) indices;
    uint noOfRecords;
    mapping (address => bool) canCreate;
    Request[] requests;
    
    constructor (address _owner, bool _isdoc, address _doc) public {
        ownerPatient = _owner;
        noOfRecords = 0;
        if (_isdoc == true) {
            canCreate[_doc] = true;
        }
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
        records.push(record); 
        records[noOfRecords].canView[msg.sender] = true;
        indices[_id] = noOfRecords;
        noOfRecords++;
    }
    
    function addRequest(uint _id, bool _isView) public {
        Request memory request = Request({
            recordID: _id,
            viewer: msg.sender,
            isView: _isView
        });
        requests.push(request);
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
        require(record.canView[msg.sender] , "You dont have permission");
        return (record.recordID, record.creatorDoc, record.description);
    }
}
