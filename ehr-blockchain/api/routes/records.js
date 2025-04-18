const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const { create } = require('ipfs-http-client');
const Web3 = require('web3');
const Record = require('../models/Record');
const User = require('../models/User');
const { auth, roleAuth } = require('../middleware/auth');
const EHR = require('../blockchain/contracts/EHR.json');

// Initialize Web3 and IPFS
const web3 = new Web3(process.env.BLOCKCHAIN_NODE_URL || 'http://localhost:8545');
const ipfs = create({ url: process.env.IPFS_NODE_URL || 'http://localhost:5001' });

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JPEG, PNG and PDF files are allowed.'));
        }
    }
});

// Add new medical record
router.post('/', 
    auth,
    roleAuth(['DOCTOR', 'HOSPITAL', 'PHARMACY', 'CLINIC']),
    upload.single('file'),
    [
        body('patientAddress').custom((value) => web3.utils.isAddress(value))
            .withMessage('Invalid patient wallet address'),
        body('recordType')
            .isIn(['PRESCRIPTION', 'LAB_RESULT', 'DIAGNOSIS', 'MEDICAL_HISTORY', 'VACCINATION'])
            .withMessage('Invalid record type'),
        body('description').trim().notEmpty().withMessage('Description is required'),
        body('metadata.facility').trim().notEmpty().withMessage('Facility name is required'),
        body('metadata.doctor').trim().notEmpty().withMessage('Doctor name is required')
    ],
    async (req, res) => {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    errors: errors.array()
                });
            }

            // Check if patient exists and has authorized the provider
            const patient = await User.findOne({ walletAddress: req.body.patientAddress });
            if (!patient) {
                return res.status(404).json({
                    success: false,
                    message: 'Patient not found'
                });
            }

            if (!patient.authorizedProviders.includes(req.user.walletAddress)) {
                return res.status(403).json({
                    success: false,
                    message: 'Not authorized to add records for this patient'
                });
            }

            // Upload file to IPFS
            const fileBuffer = req.file.buffer;
            const result = await ipfs.add(fileBuffer);
            const fileHash = result.path;

            // Create blockchain record
            const contract = new web3.eth.Contract(EHR.abi, process.env.EHR_CONTRACT_ADDRESS);
            const tx = await contract.methods.addMedicalRecord(
                req.body.patientAddress,
                fileHash,
                req.body.recordType,
                req.body.description
            ).send({ from: req.user.walletAddress });

            const blockchainRecordId = tx.events.RecordAdded.returnValues.recordId;

            // Create database record
            const record = new Record({
                patientAddress: req.body.patientAddress,
                uploaderAddress: req.user.walletAddress,
                recordType: req.body.recordType,
                description: req.body.description,
                fileHash: fileHash,
                blockchainRecordId: blockchainRecordId,
                metadata: {
                    date: new Date(),
                    facility: req.body.metadata.facility,
                    doctor: req.body.metadata.doctor,
                    additionalNotes: req.body.metadata.additionalNotes,
                    attachments: [{
                        fileHash: fileHash,
                        fileName: req.file.originalname,
                        fileType: req.file.mimetype,
                        uploadDate: new Date()
                    }]
                }
            });

            // Add initial access log
            record.addAccessLog(
                req.user.walletAddress,
                'CREATE',
                req.ip
            );

            await record.save();

            res.status(201).json({
                success: true,
                message: 'Medical record created successfully',
                data: {
                    recordId: record._id,
                    blockchainRecordId: blockchainRecordId,
                    fileHash: fileHash
                }
            });
        } catch (error) {
            console.error('Record creation error:', error);
            res.status(500).json({
                success: false,
                message: 'Error creating medical record',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

// Get patient records
router.get('/patient/:patientAddress', 
    auth,
    async (req, res) => {
        try {
            const { patientAddress } = req.params;

            // Verify patient exists
            const patient = await User.findOne({ walletAddress: patientAddress });
            if (!patient) {
                return res.status(404).json({
                    success: false,
                    message: 'Patient not found'
                });
            }

            // Check authorization
            if (req.user.walletAddress !== patientAddress && 
                !patient.authorizedProviders.includes(req.user.walletAddress)) {
                return res.status(403).json({
                    success: false,
                    message: 'Not authorized to view these records'
                });
            }

            // Get records from database
            const records = await Record.find({ 
                patientAddress,
                status: 'ACTIVE'
            }).sort({ 'metadata.date': -1 });

            // Add access log for each record
            for (let record of records) {
                record.addAccessLog(
                    req.user.walletAddress,
                    'VIEW',
                    req.ip
                );
                await record.save();
            }

            res.json({
                success: true,
                data: records
            });
        } catch (error) {
            console.error('Record retrieval error:', error);
            res.status(500).json({
                success: false,
                message: 'Error retrieving medical records',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

// Get record access logs
router.get('/:recordId/access-logs',
    auth,
    async (req, res) => {
        try {
            const record = await Record.findById(req.params.recordId);
            if (!record) {
                return res.status(404).json({
                    success: false,
                    message: 'Record not found'
                });
            }

            // Check authorization
            if (req.user.walletAddress !== record.patientAddress) {
                return res.status(403).json({
                    success: false,
                    message: 'Not authorized to view access logs'
                });
            }

            res.json({
                success: true,
                data: record.accessLog
            });
        } catch (error) {
            console.error('Access log retrieval error:', error);
            res.status(500).json({
                success: false,
                message: 'Error retrieving access logs',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

module.exports = router;
