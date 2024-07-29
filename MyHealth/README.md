# Wellness Smart Contract

## Overview

This project implements a Clarity smart contract for managing health records, insurance claims, and medical bills on the Stacks blockchain. The contract, named "wellness", provides functionality for storing and retrieving medical records, processing insurance claims, managing bills, and controlling user access through role-based authorization.

## Features

- Medical Records Management
- Insurance Claim Processing
- Medical Bill Management
- Role-based User Authorization

## Contract Functions

### Read-only Functions

1. `get-medical-record`: Retrieves a patient's medical record.
2. `calculate-payout`: Calculates the insurance payout for a claim.
3. `get-bill`: Retrieves details of a medical bill.
4. `get-discounted-price`: Calculates a discounted price (25% off).
5. `is-user-authorized`: Checks if a user is authorized for a specific role.

### Public Functions

1. `add-medical-record`: Adds a new medical record for a patient.
2. `submit-claim`: Submits an insurance claim and calculates the payout.
3. `add-bill`: Adds a new medical bill.
4. `pay-bill`: Marks a bill as paid.
5. `authorize-user`: Authorizes a user for a specific role.

## Installation

To use this smart contract, you need to have the Clarity language and the Stacks blockchain development environment set up. Follow these steps:

1. Install [Clarinet](https://github.com/hirosystems/clarinet), the Clarity development tool.
2. Clone this repository:
   ```
   git clone <repository-url>
   cd MyHealthRecords
   ```
3. Deploy the contract using Clarinet or your preferred Stacks deployment method.

## Usage

After deploying the contract, you can interact with it using the Stacks CLI, a custom frontend, or through direct contract calls. Here are some example interactions:

1. Adding a medical record:
   ```
   (contract-call? .wellness add-medical-record u12345 "Patient health record content")
   ```

2. Submitting an insurance claim:
   ```
   (contract-call? .wellness submit-claim u5000)
   ```

3. Adding a bill:
   ```
   (contract-call? .wellness add-bill "Annual Checkup" u200)
   ```

4. Authorizing a user:
   ```
   (contract-call? .wellness authorize-user 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "doctor")
   ```

## Development

To contribute to this project:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

 MIT

## Contact

Ganiyat Yakub - yakubganiyat@gmail.com

Project Link: [https://github.com/Ganyak07/MyHealthRecords.git]