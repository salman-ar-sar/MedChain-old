pragma solidity ^0.4.26;

contract UserFactory {
    mapping (address => address) public patientsAddress;
    mapping (address => address) public doctorsAddress;
    mapping (address => address) public addressPatients;
    mapping (address => address) public addressDoctors;
    
    modifier registered {
        require(doctorsAddress[msg.sender] == 0x0000000000000000000000000000000000000000 && patientsAddress[msg.sender] == 0x0000000000000000000000000000000000000000, "Already registered as doctor or patient");
        _;
    }
    
    function registerPatient(string memory _name, uint _age, string memory _gender, string memory _bloodGroup) public registered {
        address newPatient = new Patient(msg.sender, false, 0x00, _name, _age, _gender, _bloodGroup);
        patientsAddress[msg.sender] = newPatient;
        addressPatients[newPatient] = msg.sender;
    }
    
    function addPatients(address _pat, address _dep) public {
        patientsAddress[_pat] = _dep;
        addressPatients[_dep] = _pat;
    }
    
    function registerDoctor(string memory _name, string memory _specialisation, string memory _hospName, uint _docID) public registered {
        address newDoctor = new Doctor(msg.sender, _name, _specialisation, _hospName, _docID);
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
    string name;
    string specialisation;
    string hospName;
    uint docID;
    
    constructor (address _owner, string memory _name, string memory _specialisation, string memory _hospName, uint _docID) public {
        ownerDoctor = _owner;
        name = _name;
        specialisation = _specialisation;
        hospName = _hospName;
        docID = _docID;
        Ufactory = UserFactory(msg.sender);
    }
    
    modifier restricted() {
        require(msg.sender == ownerDoctor);
        _;
    }
    
    function getDocSummary() public view restricted returns (string memory, string memory, string memory, uint) {
        return (name, specialisation, hospName, docID);
    }
    
    function createPatient(address _patient, string memory _name, uint _age, string memory _gender, string memory _bloodGroup) public restricted {
        address newPatient = new Patient(_patient, true, ownerDoctor, _name, _age, _gender, _bloodGroup);

        Ufactory.addPatients(_patient, newPatient);
    }
    
    function createRecord(address _patient, uint _id, string memory _name, string memory _desc) public restricted {
        address dep_patient = Ufactory.patientsAddress(_patient);
        Patient patient = Patient(dep_patient);
        patient.createRecord(_id, _name, _desc);
    }
    
    function requestPermission(address _patient, uint _id, bool _isView) public {
        address dep_patient = Ufactory.patientsAddress(_patient);
        Patient patient = Patient(dep_patient);
        patient.addRequest(_id, _isView);
    }
}

contract Patient {
    struct Record {
        uint recordID;
        address creatorDoc;
        string name;
        string description;
        mapping (address => bool) canView;
    }
    
    struct Request {
        uint recordID;
        address viewer;
        bool isView; // false for create
    }
    
    address public ownerPatient;
    string name;
    uint age;
    string gender;
    string bloodGroup;
    Record[] records;
    mapping (uint => uint) indices;
    uint noOfRecords;
    mapping (address => bool) canCreate;
    Request[] requests;
    
    constructor (address _owner, bool _isdoc, address _doc, string memory _name, uint _age, string memory _gender, string memory _bloodGroup) public {
        ownerPatient = _owner;
        noOfRecords = 0;
        if (_isdoc == true) {
            canCreate[_doc] = true;
        }
        name = _name;
        age = _age;
        gender = _gender;
        bloodGroup = _bloodGroup;
    }
    
    modifier restricted() {
        require(msg.sender == ownerPatient);
        _;
    }
    
    function getPatSummary() public view restricted returns (string memory, uint, string memory, string memory, uint) {
        return (name, age, gender, bloodGroup, noOfRecords);
    }
    
    function createRecord(uint _id, string memory _name, string memory _desc) public {
        require(canCreate[msg.sender], "You dont have permission!");
        Record memory record = Record({
            recordID: _id,
            name: _name,
            creatorDoc: msg.sender,
            description: _desc
        });
        records.push(record); 
        records[noOfRecords].canView[msg.sender] = true;
        indices[_id] = noOfRecords;
        noOfRecords++;
    }
    
    function addRequest(uint _id, bool _isView) public restricted {
        Request memory request = Request({
            recordID: _id,
            viewer: msg.sender,
            isView: _isView
        });
        requests.push(request);
    }
    
    function grantRequest(uint _id) public restricted {
        Request storage request = requests[_id];
        if (request.isView) {
            // giveViewPerm(request.recordID, request.viewer);
            Record storage record = records[indices[request.recordID]];
            
            record.canView[request.viewer] = true;
        }
        else {
            // giveCreatePerm(request.viewer);
            canCreate[request.viewer] = true;
        }
    }
    
    function revokeRequest(uint _id) public restricted {
        Request storage request = requests[_id];
        if (request.isView) {
            // giveViewPerm(request.recordID, request.viewer);
            Record storage record = records[indices[request.recordID]];
            
            record.canView[request.viewer] = false;
        }
        else {
            // giveCreatePerm(request.viewer);
            canCreate[request.viewer] = false;
        }
    }
    
    // function giveViewPerm(uint _id, address _doc) private {
    //     Record storage record = records[indices[_id]];
    //     require(!record.canView[msg.sender], "You already have permission");
        
    //     record.canView[_doc] = true;
    // }
    
    // function revokeViewPerm(uint _id, address _doc) private {
    //     Record storage record = records[indices[_id]];
        
    //     record.canView[_doc] = false;
    // }
    
    // function giveCreatePerm(address _doc) private {
    //     require(!canCreate[_doc], "You dont have permission");
    
    //     canCreate[_doc] = true;
    // }
    
    // function revokeCreatePerm(address _doc) private {
    //     canCreate[_doc] = false;
    // }
    
    function viewRecord(uint _id) public view returns(uint, address, string memory) {
        Record storage record = records[indices[_id]];
        require(record.canView[msg.sender] , "You dont have permission");
        return (record.recordID, record.creatorDoc, record.description);
    }
    
    function view1Record(uint _index) public view restricted returns(uint, address, string memory) {
        Record storage record = records[_index];
        return (record.recordID, record.creatorDoc, record.description);
    }
}

// contract External
