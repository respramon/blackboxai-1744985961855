const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const Web3 = require('web3');

// Initialize Web3
const web3 = new Web3(process.env.BLOCKCHAIN_NODE_URL || 'http://localhost:8545');

// Validation middleware
const registerValidation = [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Invalid email address'),
    body('password')
        .isLength({ min: 8 })
        .withMessage('Password must be at least 8 characters long')
        .matches(/\d/)
        .withMessage('Password must contain a number')
        .matches(/[A-Z]/)
        .withMessage('Password must contain an uppercase letter'),
    body('role').isIn(['PATIENT', 'DOCTOR', 'HOSPITAL', 'PHARMACY', 'CLINIC'])
        .withMessage('Invalid role'),
    body('phoneNumber').matches(/^\+?[\d\s-]+$/).withMessage('Invalid phone number'),
    body('walletAddress').custom((value) => web3.utils.isAddress(value))
        .withMessage('Invalid wallet address')
];

// Register new user
router.post('/register', registerValidation, async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { name, email, password, role, phoneNumber, walletAddress } = req.body;

        // Check if user already exists
        let user = await User.findOne({ $or: [{ email }, { walletAddress }] });
        if (user) {
            return res.status(400).json({
                success: false,
                message: 'User already exists with this email or wallet address'
            });
        }

        // Create new user
        user = new User({
            name,
            email,
            password,
            role,
            phoneNumber,
            walletAddress
        });

        // Generate OTP for verification
        const otp = user.generateOTP();

        await user.save();

        // TODO: Send OTP via SMS/email
        // For development, return OTP in response
        const token = jwt.sign(
            { userId: user._id, role: user.role, walletAddress: user.walletAddress },
            process.env.JWT_SECRET,
            { expiresIn: '1d' }
        );

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            data: {
                token,
                user: {
                    id: user._id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    walletAddress: user.walletAddress,
                    isVerified: user.isVerified
                },
                otp // Remove in production
            }
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Error registering user',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Login
router.post('/login', [
    body('email').isEmail().withMessage('Invalid email address'),
    body('password').notEmpty().withMessage('Password is required')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { email, password } = req.body;

        // Find user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        // Check password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        // Generate token
        const token = jwt.sign(
            { userId: user._id, role: user.role, walletAddress: user.walletAddress },
            process.env.JWT_SECRET,
            { expiresIn: '1d' }
        );

        res.json({
            success: true,
            data: {
                token,
                user: {
                    id: user._id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    walletAddress: user.walletAddress,
                    isVerified: user.isVerified
                }
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Error during login',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Verify OTP
router.post('/verify-otp', auth, [
    body('otp').isLength({ min: 6, max: 6 }).isNumeric()
        .withMessage('Invalid OTP format')
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const user = await User.findById(req.user.userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        try {
            user.verifyOTP(req.body.otp);
            user.isVerified = true;
            await user.save();

            res.json({
                success: true,
                message: 'OTP verified successfully'
            });
        } catch (error) {
            res.status(400).json({
                success: false,
                message: error.message
            });
        }
    } catch (error) {
        console.error('OTP verification error:', error);
        res.status(500).json({
            success: false,
            message: 'Error verifying OTP',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Enable biometric authentication
router.post('/enable-biometric', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        user.biometricEnabled = true;
        await user.save();

        res.json({
            success: true,
            message: 'Biometric authentication enabled successfully'
        });
    } catch (error) {
        console.error('Biometric enable error:', error);
        res.status(500).json({
            success: false,
            message: 'Error enabling biometric authentication',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

module.exports = router;
