// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EHR {
    // Structs
    struct User {
        string name;
        string role; // "PATIENT", "DOCTOR", "HOSPITAL", "PHARMACY", "CLINIC"
        bool isRegistered;
        mapping(address => bool) authorizedProviders; // For patients: healthcare providers they've authorized
    }

    struct MedicalRecord {
        uint256 recordId;
        address patientAddress;
        address uploaderAddress;
        string fileHash;       // IPFS hash of the medical record
        string recordType;     // e.g., "PRESCRIPTION", "LAB_RESULT", "DIAGNOSIS"
        string description;
        uint256 timestamp;
        bool isActive;
    }

    struct AccessLog {
        address accessor;
        uint256 timestamp;
        string action; // "VIEW", "CREATE", "UPDATE"
    }

    // State variables
    mapping(address => User) public users;
    mapping(address => MedicalRecord[]) private patientRecords;
    mapping(uint256 => AccessLog[]) private recordAccessLogs;
    
    uint256 private recordCounter;

    // Events
    event UserRegistered(address indexed userAddress, string role);
    event RecordAdded(uint256 indexed recordId, address indexed patientAddress, string recordType);
    event AccessGranted(address indexed patientAddress, address indexed providerAddress);
    event AccessRevoked(address indexed patientAddress, address indexed providerAddress);
    event RecordAccessed(uint256 indexed recordId, address indexed accessor, string action);

    // Modifiers
    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User is not registered");
        _;
    }

    modifier onlyAuthorizedProvider(address patientAddress) {
        require(
            users[msg.sender].isRegistered &&
            (msg.sender == patientAddress || users[patientAddress].authorizedProviders[msg.sender]),
            "Not authorized to access patient records"
        );
        _;
    }

    // Functions
    function registerUser(string memory _name, string memory _role) public {
        require(!users[msg.sender].isRegistered, "User already registered");
        require(
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("PATIENT")) ||
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("DOCTOR")) ||
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("HOSPITAL")) ||
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("PHARMACY")) ||
            keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("CLINIC")),
            "Invalid role"
        );

        User storage newUser = users[msg.sender];
        newUser.name = _name;
        newUser.role = _role;
        newUser.isRegistered = true;

        emit UserRegistered(msg.sender, _role);
    }

    function authorizeProvider(address providerAddress) public onlyRegisteredUser {
        require(
            keccak256(abi.encodePacked(users[msg.sender].role)) == keccak256(abi.encodePacked("PATIENT")),
            "Only patients can authorize providers"
        );
        require(users[providerAddress].isRegistered, "Provider is not registered");
        require(
            keccak256(abi.encodePacked(users[providerAddress].role)) != keccak256(abi.encodePacked("PATIENT")),
            "Cannot authorize a patient"
        );

        users[msg.sender].authorizedProviders[providerAddress] = true;
        emit AccessGranted(msg.sender, providerAddress);
    }

    function revokeProviderAccess(address providerAddress) public onlyRegisteredUser {
        require(
            keccak256(abi.encodePacked(users[msg.sender].role)) == keccak256(abi.encodePacked("PATIENT")),
            "Only patients can revoke provider access"
        );

        users[msg.sender].authorizedProviders[providerAddress] = false;
        emit AccessRevoked(msg.sender, providerAddress);
    }

    function addMedicalRecord(
        address patientAddress,
        string memory fileHash,
        string memory recordType,
        string memory description
    ) public onlyAuthorizedProvider(patientAddress) {
        recordCounter++;
        
        MedicalRecord memory newRecord = MedicalRecord({
            recordId: recordCounter,
            patientAddress: patientAddress,
            uploaderAddress: msg.sender,
            fileHash: fileHash,
            recordType: recordType,
            description: description,
            timestamp: block.timestamp,
            isActive: true
        });

        patientRecords[patientAddress].push(newRecord);

        // Log the access
        AccessLog memory accessLog = AccessLog({
            accessor: msg.sender,
            timestamp: block.timestamp,
            action: "CREATE"
        });
        recordAccessLogs[recordCounter].push(accessLog);

        emit RecordAdded(recordCounter, patientAddress, recordType);
    }

    function getPatientRecords(address patientAddress) public view 
        onlyAuthorizedProvider(patientAddress) 
        returns (MedicalRecord[] memory) 
    {
        return patientRecords[patientAddress];
    }

    function getRecordAccessLogs(uint256 recordId) public view returns (AccessLog[] memory) {
        MedicalRecord[] memory records = patientRecords[msg.sender];
        bool isAuthorized = false;
        
        // Check if the requester is either the patient or an authorized provider
        for (uint i = 0; i < records.length; i++) {
            if (records[i].recordId == recordId) {
                isAuthorized = true;
                break;
            }
        }
        
        require(isAuthorized, "Not authorized to view access logs");
        return recordAccessLogs[recordId];
    }

    // Helper function to check if a provider is authorized
    function isProviderAuthorized(address patientAddress, address providerAddress) 
        public view returns (bool) 
    {
        return users[patientAddress].authorizedProviders[providerAddress];
    }
}
