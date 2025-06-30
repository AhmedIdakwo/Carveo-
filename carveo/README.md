## 📘 `Carveo` – Vintage Car Syndicate Smart Contract

`Carveo` is a Clarity smart contract that powers a decentralized syndicate for **fractional ownership**, **rental income distribution**, and **collaborative rally events** involving classic collectible cars. This contract allows users to collectively own vintage automobiles and participate in the operational and experiential benefits they generate.

---

### 🚗 Core Features

#### ✅ Vehicle Registration

* Only the `GARAGE_MASTER` can register vehicles.
* Each vehicle includes:

  * Model name
  * Total shares available
  * Share price
  * Monthly rental income value
  * Assigned chief mechanic

#### 💰 Fractional Ownership

* Users can buy shares of a registered classic car.
* Ownership is tracked per user and vehicle.

#### 📈 Automated Income Distribution

* Each month, a vehicle’s rental income can be distributed proportionally based on shares owned.
* Owners can individually claim their share of the income if they haven't already.

#### 🏁 Rally Event Governance

* Any shareholder can propose a rally event.
* Owners vote using their share balance to support or reject event participation.
* Votes are time-limited and tracked per participant.

---

### 🛠️ Functions Overview

#### 🔧 Public Functions

| Function Name       | Description                                                           |
| ------------------- | --------------------------------------------------------------------- |
| `register-vehicle`  | Registers a new classic car                                           |
| `buy-shares`        | Allows users to purchase shares in a car                              |
| `distribute-income` | Allows the chief mechanic to initiate income distribution for a month |
| `claim-income`      | Allows users to claim their monthly share of rental income            |
| `create-rally`      | Creates a new rally event proposal                                    |
| `vote-rally`        | Lets shareholders vote for or against a rally event                   |

#### 📖 Read-only Functions

| Function Name            | Description                                        |
| ------------------------ | -------------------------------------------------- |
| `get-vehicle`            | Fetch a registered car’s data                      |
| `get-share-balance`      | Returns the number of shares a user owns in a car  |
| `get-rally`              | Returns details of a proposed rally                |
| `calculate-income-share` | Estimates the user’s rental income share for a car |

---

### ⚠️ Errors & Enforcement

| Error Constant             | Description                               |
| -------------------------- | ----------------------------------------- |
| `ERR_UNAUTHORIZED_DRIVER`  | Action requires ownership or special role |
| `ERR_INSUFFICIENT_SHARES`  | User does not own required shares         |
| `ERR_VEHICLE_NOT_FOUND`    | Referenced vehicle does not exist         |
| `ERR_INVALID_QUANTITY`     | Share quantity must be positive           |
| `ERR_RALLY_NOT_FOUND`      | Referenced rally event does not exist     |
| `ERR_ALREADY_PARTICIPATED` | Duplicate voting attempt                  |

---

### 🔒 Roles & Access Control

* **Garage Master**: The contract deployer who can register cars.
* **Chief Mechanic**: Assigned per vehicle; can trigger income distribution.
* **Owners**: Users who purchase shares; can vote on rallies and claim income.

---

### 💡 Use Cases

* **Vintage Car Collectors**: Lower entry cost to participate in exotic car investments.
* **DAO Members**: Democratized decision-making on event participation and asset usage.
* **Investors**: Passive income through share-based revenue distribution.
