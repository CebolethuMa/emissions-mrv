// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title EmissionsMRV
/// @notice Blockchain-based Monitoring, Reporting and Verification (MRV) system
/// for greenhouse gas emissions reported by a manufacturing company.
contract EmissionsMRV {

    // ---------- State ----------

    address public regulator; // the account that deployed the contract, acts as the regulator/admin

    struct Facility {
        uint256 id;
        string name;
        string location;
        address operator;   // the wallet allowed to submit emissions for this facility
        bool isRegistered;
    }

    struct EmissionRecord {
        uint256 id;
        uint256 facilityId;
        bytes32 dataHash;      // hash of the full emissions report (kept off-chain)
        uint256 reportingPeriod; // e.g. 202601 for Jan 2026
        uint256 timestamp;     // block time when the record was submitted
        address submittedBy;
    }

    mapping(uint256 => Facility) public facilities;
    mapping(uint256 => EmissionRecord) public emissionRecords;
    mapping(address => bool) public authorisedReporters;

    uint256 private nextFacilityId = 1;
    uint256 private nextRecordId = 1;

    // ---------- Events ----------

    event FacilityRegistered(uint256 indexed facilityId, string name, address operator);
    event ReporterAuthorised(address indexed reporter);
    event ReporterRevoked(address indexed reporter);
    event EmissionRecordSubmitted(
        uint256 indexed recordId,
        uint256 indexed facilityId,
        bytes32 dataHash,
        uint256 reportingPeriod,
        address submittedBy
    );

    // ---------- Custom errors ----------

    error NotRegulator();
    error NotAuthorised();
    error FacilityDoesNotExist();
    error InvalidInput();

    // ---------- Modifiers ----------

    modifier onlyRegulator() {
        if (msg.sender != regulator) revert NotRegulator();
        _;
    }

    modifier onlyAuthorised() {
        if (!authorisedReporters[msg.sender] && msg.sender != regulator) revert NotAuthorised();
        _;
    }

    // ---------- Constructor ----------

    constructor() {
        regulator = msg.sender;
        authorisedReporters[msg.sender] = true;
    }

    // ---------- Facility management ----------

    function registerFacility(string calldata _name, string calldata _location, address _operator)
        external
        onlyRegulator
        returns (uint256)
    {
        if (bytes(_name).length == 0) revert InvalidInput();
        if (_operator == address(0)) revert InvalidInput();

        uint256 facilityId = nextFacilityId;
        facilities[facilityId] = Facility(facilityId, _name, _location, _operator, true);
        authorisedReporters[_operator] = true;

        nextFacilityId++;

        emit FacilityRegistered(facilityId, _name, _operator);
        return facilityId;
    }

    function authoriseReporter(address _reporter) external onlyRegulator {
        if (_reporter == address(0)) revert InvalidInput();
        authorisedReporters[_reporter] = true;
        emit ReporterAuthorised(_reporter);
    }

    function revokeReporter(address _reporter) external onlyRegulator {
        authorisedReporters[_reporter] = false;
        emit ReporterRevoked(_reporter);
    }

    // ---------- Emissions reporting ----------

    function submitEmissionRecord(uint256 _facilityId, bytes32 _dataHash, uint256 _reportingPeriod)
        external
        onlyAuthorised
        returns (uint256)
    {
        if (!facilities[_facilityId].isRegistered) revert FacilityDoesNotExist();
        if (_dataHash == bytes32(0)) revert InvalidInput();

        uint256 recordId = nextRecordId;
        emissionRecords[recordId] = EmissionRecord(
            recordId,
            _facilityId,
            _dataHash,
            _reportingPeriod,
            block.timestamp,
            msg.sender
        );

        nextRecordId++;

        emit EmissionRecordSubmitted(recordId, _facilityId, _dataHash, _reportingPeriod, msg.sender);
        return recordId;
    }

    // ---------- Read-only verification functions ----------

    function getFacility(uint256 _facilityId) external view returns (Facility memory) {
        if (!facilities[_facilityId].isRegistered) revert FacilityDoesNotExist();
        return facilities[_facilityId];
    }

    function getEmissionRecord(uint256 _recordId) external view returns (EmissionRecord memory) {
        return emissionRecords[_recordId];
    }

    function totalFacilities() external view returns (uint256) {
        return nextFacilityId - 1;
    }

    function totalRecords() external view returns (uint256) {
        return nextRecordId - 1;
    }
}
