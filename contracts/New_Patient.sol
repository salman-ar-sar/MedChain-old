pragma solidity ^0.5.0;

contract patient {
    struct Record {
        uint recordID;
        address creatorDoc;
        string description;
        mapping (address => bool) canView;
    }
    
    address public ownerPatient;
    Record[] public records;
    mapping (uint => uint) indices;
    uint noOfRecords;
    mapping (address => bool) canCreate;
    
    constructor () public {
        ownerPatient = msg.sender;
        noOfRecords = 0;
    }
    
    modifier restricted() {
        require(msg.sender == ownerPatient);
        _;
    }
    
    function createRecord(uint _id, address _doc, string memory _desc) public {
        require(canCreate[msg.sender], "You dont have permission!");
        Record memory record = Record({
            recordID: _id,
            creatorDoc: _doc,
            description: _desc
        });
        
        records.push(record); 
        indices[_id] = noOfRecords;
        noOfRecords++;
    }
    
    function giveViewPerm(uint _id) public restricted {
        Record storage record = records[indices[_id]];
        require(!record.canView[msg.sender], "You already have permission");
        
        record.canView[msg.sender] = true;
    }
    
    function revokeViewPerm(uint _id) public restricted {
        Record storage record = records[indices[_id]];
        
        record.canView[msg.sender] = false;
    }
    
    function giveCreatePerm(address _doc) public restricted {
        require(!canCreate[_doc]);
        
        canCreate[_doc] = true;
    }
    
    function revokeCreatePerm(address _doc) public restricted {
        // require(!canCreate[_doc]);
        
        canCreate[_doc] = false;
    }
    
    function viewRecord(uint _id) public view returns(Record){
        Record memory record = records[indices[_id]];
        require(record.canView[msg.sender], "You dont have permission");
        return record;
    }
}