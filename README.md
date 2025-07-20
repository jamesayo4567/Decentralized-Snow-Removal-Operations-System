# Decentralized Snow Removal Operations System

A comprehensive blockchain-based system for managing municipal snow removal operations using Clarity smart contracts on the Stacks blockchain.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of snow removal operations:

### 1. Route Prioritization Contract (`route-prioritization.clar`)
- Plans and schedules snow plowing routes for city streets
- Prioritizes routes based on traffic volume, emergency access, and street classification
- Manages route assignments and scheduling

### 2. Equipment Deployment Contract (`equipment-deployment.clar`)
- Assigns plows and salt trucks to specific areas and routes
- Tracks equipment availability and maintenance status
- Manages equipment allocation and deployment schedules

### 3. Contractor Coordination Contract (`contractor-coordination.clar`)
- Manages agreements with private snow removal service providers
- Handles contractor assignments and performance tracking
- Manages contract terms and payment schedules

### 4. Resident Notification Contract (`resident-notification.clar`)
- Sends alerts to citizens about parking restrictions during snow events
- Manages notification preferences and delivery methods
- Tracks notification delivery and resident responses

### 5. Cost Tracking Contract (`cost-tracking.clar`)
- Monitors snow removal expenses across all operations
- Tracks budget allocation and spending by category
- Generates cost reports and budget analysis

## Features

- **Decentralized Management**: All operations recorded on blockchain for transparency
- **Priority-Based Routing**: Smart route prioritization based on multiple factors
- **Resource Optimization**: Efficient allocation of equipment and personnel
- **Contractor Integration**: Seamless coordination with private service providers
- **Citizen Engagement**: Real-time notifications and communication
- **Cost Control**: Comprehensive expense tracking and budget management

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized data structures and error handling patterns.

### Data Types
- Routes: Street segments with priority levels and characteristics
- Equipment: Plows, salt trucks, and other snow removal vehicles
- Contractors: Private service providers with capabilities and rates
- Notifications: Alerts and messages for residents
- Expenses: Cost tracking entries with categories and timestamps

### Error Handling
All contracts implement comprehensive error handling with descriptive error codes for debugging and user feedback.

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing

### Usage Examples

#### Planning Routes
\`\`\`clarity
(contract-call? .route-prioritization add-route
"Main Street"
u1
u100
"primary")
\`\`\`

#### Deploying Equipment
\`\`\`clarity
(contract-call? .equipment-deployment assign-equipment
u1
"Main Street"
block-height)
\`\`\`

#### Managing Contractors
\`\`\`clarity
(contract-call? .contractor-coordination add-contractor
'SP1CONTRACTOR
"Snow Pro Services"
u50)
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
