const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth, roleAuth } = require('../middleware/auth');

// Get user profile
router.get('/profile', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.userId)
            .select('-password -verificationData');
        
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.json({
            success: true,
            data: user
        });
    } catch (error) {
        console.error('Profile retrieval error:', error);
        res.status(500).json({
            success: false,
            message: 'Error retrieving user profile',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Update user profile
router.put('/profile', 
    auth,
    [
        body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
        body('phoneNumber').optional().matches(/^\+?[\d\s-]+$/).withMessage('Invalid phone number'),
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

            const updateData = {};
            if (req.body.name) updateData.name = req.body.name;
            if (req.body.phoneNumber) updateData.phoneNumber = req.body.phoneNumber;

            const user = await User.findByIdAndUpdate(
                req.user.userId,
                { $set: updateData },
                { new: true }
            ).select('-password -verificationData');

            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'User not found'
                });
            }

            res.json({
                success: true,
                message: 'Profile updated successfully',
                data: user
            });
        } catch (error) {
            console.error('Profile update error:', error);
            res.status(500).json({
                success: false,
                message: 'Error updating user profile',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

// Get healthcare providers
router.get('/providers', auth, async (req, res) => {
    try {
        const providers = await User.find({
            role: { $in: ['DOCTOR', 'HOSPITAL', 'PHARMACY', 'CLINIC'] },
            isVerified: true
        }).select('name role walletAddress');

        res.json({
            success: true,
            data: providers
        });
    } catch (error) {
        console.error('Providers retrieval error:', error);
        res.status(500).json({
            success: false,
            message: 'Error retrieving healthcare providers',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Authorize healthcare provider
router.post('/authorize-provider',
    auth,
    roleAuth(['PATIENT']),
    [
        body('providerAddress').custom((value) => web3.utils.isAddress(value))
            .withMessage('Invalid provider wallet address')
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

            const provider = await User.findOne({ 
                walletAddress: req.body.providerAddress,
                role: { $in: ['DOCTOR', 'HOSPITAL', 'PHARMACY', 'CLINIC'] },
                isVerified: true
            });

            if (!provider) {
                return res.status(404).json({
                    success: false,
                    message: 'Healthcare provider not found or not verified'
                });
            }

            const user = await User.findById(req.user.userId);
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'User not found'
                });
            }

            // Add provider to authorized list if not already authorized
            if (!user.authorizedProviders.includes(req.body.providerAddress)) {
                user.authorizedProviders.push(req.body.providerAddress);
                await user.save();
            }

            res.json({
                success: true,
                message: 'Healthcare provider authorized successfully'
            });
        } catch (error) {
            console.error('Provider authorization error:', error);
            res.status(500).json({
                success: false,
                message: 'Error authorizing healthcare provider',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

// Revoke healthcare provider authorization
router.post('/revoke-provider',
    auth,
    roleAuth(['PATIENT']),
    [
        body('providerAddress').custom((value) => web3.utils.isAddress(value))
            .withMessage('Invalid provider wallet address')
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

            const user = await User.findById(req.user.userId);
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'User not found'
                });
            }

            // Remove provider from authorized list
            user.authorizedProviders = user.authorizedProviders.filter(
                address => address !== req.body.providerAddress
            );
            await user.save();

            res.json({
                success: true,
                message: 'Healthcare provider authorization revoked successfully'
            });
        } catch (error) {
            console.error('Provider revocation error:', error);
            res.status(500).json({
                success: false,
                message: 'Error revoking healthcare provider authorization',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    }
);

module.exports = router;
