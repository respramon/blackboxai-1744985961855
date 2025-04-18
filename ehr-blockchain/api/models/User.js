const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true
    },
    password: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['PATIENT', 'DOCTOR', 'HOSPITAL', 'PHARMACY', 'CLINIC'],
        required: true
    },
    walletAddress: {
        type: String,
        required: true,
        unique: true
    },
    phoneNumber: {
        type: String,
        required: true
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    authorizedProviders: [{
        type: String // wallet addresses of authorized healthcare providers
    }],
    verificationData: {
        otp: String,
        otpExpiry: Date,
        attempts: {
            type: Number,
            default: 0
        }
    },
    biometricEnabled: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
    if (this.isModified('password')) {
        this.password = await bcrypt.hash(this.password, 10);
    }
    next();
});

// Method to compare password
userSchema.methods.comparePassword = async function(password) {
    return bcrypt.compare(password, this.password);
};

// Generate OTP
userSchema.methods.generateOTP = function() {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    this.verificationData.otp = otp;
    this.verificationData.otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes expiry
    this.verificationData.attempts = 0;
    return otp;
};

// Verify OTP
userSchema.methods.verifyOTP = function(otp) {
    if (this.verificationData.attempts >= 3) {
        throw new Error('Maximum OTP verification attempts exceeded');
    }
    
    if (Date.now() > this.verificationData.otpExpiry) {
        throw new Error('OTP has expired');
    }
    
    this.verificationData.attempts += 1;
    
    if (this.verificationData.otp !== otp) {
        throw new Error('Invalid OTP');
    }
    
    return true;
};

const User = mongoose.model('User', userSchema);

module.exports = User;
