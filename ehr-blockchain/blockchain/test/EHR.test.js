const EHR = artifacts.require("EHR");
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

contract("EHR", accounts => {
    const [admin, patient, doctor, hospital, pharmacy, unauthorized] = accounts;
    let ehrContract;

    beforeEach(async () => {
        ehrContract = await EHR.new();
    });

    describe("User Registration", () => {
        it("should allow a user to register", async () => {
            const result = await ehrContract.registerUser("John Doe", "PATIENT", { from: patient });
            
            expectEvent(result, 'UserRegistered', {
                userAddress: patient,
                role: "PATIENT"
            });

            const user = await ehrContract.users(patient);
            assert.equal(user.name, "John Doe");
            assert.equal(user.role, "PATIENT");
            assert.equal(user.isRegistered, true);
        });

        it("should not allow duplicate registration", async () => {
            await ehrContract.registerUser("John Doe", "PATIENT", { from: patient });
            
            await expectRevert(
                ehrContract.registerUser("John Doe", "PATIENT", { from: patient }),
                "User already registered"
            );
        });

        it("should not allow invalid roles", async () => {
            await expectRevert(
                ehrContract.registerUser("John Doe", "INVALID_ROLE", { from: patient }),
                "Invalid role"
            );
        });
    });

    describe("Provider Authorization", () => {
        beforeEach(async () => {
            await ehrContract.registerUser("John Doe", "PATIENT", { from: patient });
            await ehrContract.registerUser("Dr. Smith", "DOCTOR", { from: doctor });
        });

        it("should allow patient to authorize a provider", async () => {
            const result = await ehrContract.authorizeProvider(doctor, { from: patient });
            
            expectEvent(result, 'AccessGranted', {
                patientAddress: patient,
                providerAddress: doctor
            });

            const isAuthorized = await ehrContract.isProviderAuthorized(patient, doctor);
            assert.equal(isAuthorized, true);
        });

        it("should allow patient to revoke provider access", async () => {
            await ehrContract.authorizeProvider(doctor, { from: patient });
            const result = await ehrContract.revokeProviderAccess(doctor, { from: patient });
            
            expectEvent(result, 'AccessRevoked', {
                patientAddress: patient,
                providerAddress: doctor
            });

            const isAuthorized = await ehrContract.isProviderAuthorized(patient, doctor);
            assert.equal(isAuthorized, false);
        });

        it("should not allow non-patients to authorize providers", async () => {
            await expectRevert(
                ehrContract.authorizeProvider(doctor, { from: doctor }),
                "Only patients can authorize providers"
            );
        });
    });

    describe("Medical Records", () => {
        beforeEach(async () => {
            await ehrContract.registerUser("John Doe", "PATIENT", { from: patient });
            await ehrContract.registerUser("Dr. Smith", "DOCTOR", { from: doctor });
            await ehrContract.authorizeProvider(doctor, { from: patient });
        });

        it("should allow authorized provider to add medical record", async () => {
            const result = await ehrContract.addMedicalRecord(
                patient,
                "QmHash123",
                "PRESCRIPTION",
                "Regular checkup prescription",
                { from: doctor }
            );

            expectEvent(result, 'RecordAdded', {
                patientAddress: patient,
                recordType: "PRESCRIPTION"
            });

            const records = await ehrContract.getPatientRecords(patient, { from: doctor });
            assert.equal(records.length, 1);
            assert.equal(records[0].fileHash, "QmHash123");
            assert.equal(records[0].recordType, "PRESCRIPTION");
        });

        it("should not allow unauthorized provider to add medical record", async () => {
            await expectRevert(
                ehrContract.addMedicalRecord(
                    patient,
                    "QmHash123",
                    "PRESCRIPTION",
                    "Regular checkup prescription",
                    { from: unauthorized }
                ),
                "Not authorized to access patient records"
            );
        });

        it("should allow patient to view their records", async () => {
            await ehrContract.addMedicalRecord(
                patient,
                "QmHash123",
                "PRESCRIPTION",
                "Regular checkup prescription",
                { from: doctor }
            );

            const records = await ehrContract.getPatientRecords(patient, { from: patient });
            assert.equal(records.length, 1);
            assert.equal(records[0].fileHash, "QmHash123");
        });

        it("should maintain access logs for records", async () => {
            await ehrContract.addMedicalRecord(
                patient,
                "QmHash123",
                "PRESCRIPTION",
                "Regular checkup prescription",
                { from: doctor }
            );

            const records = await ehrContract.getPatientRecords(patient, { from: doctor });
            const recordId = records[0].recordId;

            const accessLogs = await ehrContract.getRecordAccessLogs(recordId, { from: patient });
            assert.equal(accessLogs.length, 1);
            assert.equal(accessLogs[0].accessor, doctor);
            assert.equal(accessLogs[0].action, "CREATE");
        });
    });
});
