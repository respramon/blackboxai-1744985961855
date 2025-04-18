# Electronic Health Record (EHR) Blockchain System

A decentralized Electronic Health Record system built on blockchain technology that provides secure, transparent, and efficient management of medical records across healthcare providers.

## Features

- Secure user registration with role-based access control
- OTP and biometric authentication
- Decentralized medical record storage using blockchain and IPFS
- Real-time record synchronization
- Comprehensive audit trail
- Provider authorization management
- HIPAA-compliant security measures

## Technology Stack

- **Smart Contracts**: Solidity (Ethereum)
- **Backend**: Node.js, Express.js
- **Database**: MongoDB
- **Blockchain**: Ethereum (Web3.js)
- **File Storage**: IPFS
- **Authentication**: JWT, OTP, Biometric

## Project Structure

```
ehr-blockchain/
├── api/                    # Backend API
│   ├── routes/            # API endpoints
│   ├── controllers/       # Business logic
│   ├── models/           # Data models
│   └── middleware/       # Auth & validation
├── blockchain/           # Smart contracts
│   ├── contracts/       # Solidity contracts
│   ├── migrations/      # Contract deployment
│   └── test/           # Contract tests
└── frontend/            # Flutter mobile app (to be implemented)
```

## Prerequisites

- Node.js (v14 or higher)
- MongoDB
- Ganache (for local blockchain)
- IPFS node
- Truffle Framework

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ehr-blockchain.git
   cd ehr-blockchain
   ```

2. Install dependencies:
   ```bash
   # Install API dependencies
   cd api
   npm install

   # Install blockchain dependencies
   cd ../blockchain
   npm install
   ```

3. Configure environment variables:
   ```bash
   # In api directory
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Start local blockchain (Ganache):
   ```bash
   ganache-cli
   ```

5. Deploy smart contracts:
   ```bash
   cd blockchain
   truffle migrate --reset
   ```

6. Start the API server:
   ```bash
   cd ../api
   npm run dev
   ```

## Smart Contract Deployment

### Local Development
```bash
cd blockchain
truffle migrate --reset
```

### Testnet (Goerli)
```bash
cd blockchain
truffle migrate --network goerli
```

### Mainnet
```bash
cd blockchain
truffle migrate --network mainnet
```

## API Documentation

### Authentication Endpoints

- POST `/api/auth/register` - Register new user
- POST `/api/auth/login` - User login
- POST `/api/auth/verify-otp` - Verify OTP
- POST `/api/auth/enable-biometric` - Enable biometric authentication

### Medical Records Endpoints

- POST `/api/records` - Add new medical record
- GET `/api/records/patient/:patientAddress` - Get patient records
- GET `/api/records/:recordId/access-logs` - Get record access logs

### User Management Endpoints

- GET `/api/users/profile` - Get user profile
- PUT `/api/users/profile` - Update user profile
- GET `/api/users/providers` - Get healthcare providers
- POST `/api/users/authorize-provider` - Authorize provider
- POST `/api/users/revoke-provider` - Revoke provider authorization

## Testing

### Smart Contract Tests
```bash
cd blockchain
npm test
```

### API Tests (to be implemented)
```bash
cd api
npm test
```

## Security Considerations

- All medical data is encrypted before being stored
- Smart contract access control mechanisms
- JWT-based authentication
- OTP verification for sensitive operations
- Regular security audits
- HIPAA compliance measures

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@ehrblockchain.com or join our Slack channel.
