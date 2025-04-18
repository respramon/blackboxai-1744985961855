const mongoose = require('mongoose');

const recordSchema = new mongoose.Schema({
    patientAddress: {
        type: String,
        required: true,
        index: true
    },
    uploaderAddress: {
        type: String,
        required: true
    },
    recordType: {
        type: String,
        enum: ['PRESCRIPTION', 'LAB_RESULT', 'DIAGNOSIS', 'MEDICAL_HISTORY', 'VACCINATION'],
        required: true
    },
    description: {
        type: String,
        required: true
    },
    fileHash: {
        type: String,
        required: true,
        unique: true
    },
    blockchainRecordId: {
        type: Number,
        required: true,
        unique: true
    },
    metadata: {
        date: {
            type: Date,
            required: true,
            default: Date.now
        },
        facility: {
            type: String,
            required: true
        },
        doctor: {
            type: String,
            required: true
        },
        additionalNotes: String,
        tags: [String],
        attachments: [{
            fileHash: String,
            fileName: String,
            fileType: String,
            uploadDate: Date
        }]
    },
    status: {
        type: String,
        enum: ['ACTIVE', 'ARCHIVED', 'PENDING_VERIFICATION'],
        default: 'ACTIVE'
    },
    accessLog: [{
        accessorAddress: String,
        timestamp: Date,
        action: {
            type: String,
            enum: ['VIEW', 'CREATE', 'UPDATE', 'ARCHIVE']
        },
        ipAddress: String
    }],
    encryptionDetails: {
        algorithm: String,
        publicKey: String,
        encryptedSymmetricKey: String
    },
    verificationStatus: {
        isVerified: {
            type: Boolean,
            default: false
        },
        verifiedBy: String,
        verificationDate: Date,
        verificationNotes: String
    }
}, {
    timestamps: true
});

// Indexes for better query performance
recordSchema.index({ 'metadata.date': -1 });
recordSchema.index({ recordType: 1, patientAddress: 1 });
recordSchema.index({ 'metadata.facility': 1 });
recordSchema.index({ 'metadata.doctor': 1 });

// Instance methods
recordSchema.methods.addAccessLog = function(accessorAddress, action, ipAddress) {
    this.accessLog.push({
        accessorAddress,
        timestamp: new Date(),
        action,
        ipAddress
    });
};

recordSchema.methods.verify = function(verifierAddress, notes) {
    this.verificationStatus = {
        isVerified: true,
        verifiedBy: verifierAddress,
        verificationDate: new Date(),
        verificationNotes: notes
    };
};

// Static methods
recordSchema.statics.getPatientRecords = function(patientAddress) {
    return this.find({ 
        patientAddress,
        status: 'ACTIVE'
    }).sort({ 'metadata.date': -1 });
};

recordSchema.statics.getRecordsByFacility = function(facilityAddress) {
    return this.find({
        'metadata.facility': facilityAddress,
        status: 'ACTIVE'
    }).sort({ 'metadata.date': -1 });
};

const Record = mongoose.model('Record', recordSchema);

module.exports = Record;
