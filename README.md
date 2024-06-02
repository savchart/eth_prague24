# Fee Optimizer

## Overview
Fee Optimizer is a project designed to dynamically adjust transaction fees based on real-time market data, ensuring fair pricing for traders and protecting liquidity providers from impermanent loss. This project leverages The Graph for data collection, advanced algorithms for fee optimization, and integrates with Uniswap to enhance the DeFi ecosystem.

## Features
- Dynamic fee adjustment based on market conditions
- Protection for liquidity providers
- Enhanced market data integration
- Improved user experience in DeFi platforms

## Data Collection with The Graph

### Prerequisites
- Python 3.x
- Subgrounds library
- Pandas library

## Data Description

The data collected and processed in the `df.csv` file consists of several key metrics that are crucial for building and optimizing the dynamic fee model. Here's a brief description of each column in the dataset:

### Columns

- **date**: The date for which the data is collected. This is derived from the Unix timestamp and converted to a human-readable format.
- **volumeUSD**: The total trading volume in USD for the ETH/USDC pool on a given day.
- **volumeToken0**: The total trading volume of Token0 (ETH) for the ETH/USDC pool on a given day.
- **volumeToken1**: The total trading volume of Token1 (USDC) for the ETH/USDC pool on a given day.
- **liquidity**: The total liquidity available in the ETH/USDC pool on a given day. This represents the amount of assets available for trading.
- **sqrtPrice**: The square root of the pool price, used internally by Uniswap's pricing algorithm.
- **tick**: The current tick of the pool. A tick is a price point in Uniswap V3 that determines the price range of the pool.
- **avgGasPrice**: The average gas price used in transactions on a given day. This is calculated from the transaction data to provide an estimate of network costs.

### Example Data

Here's a sample of what the final dataset looks like:

| date       | volumeUSD  | volumeToken0 | volumeToken1 | liquidity       | sqrtPrice  | tick | avgGasPrice |
|------------|------------|--------------|--------------|-----------------|------------|------|-------------|
| 2023-01-01 | 1000000.00 | 500.00       | 1000000.00   | 200000000000000 | 1.000000   | 1234 | 10000000000 |
| 2023-01-02 | 1500000.00 | 750.00       | 1500000.00   | 250000000000000 | 1.010000   | 1235 | 10500000000 |
| 2023-01-03 | 1200000.00 | 600.00       | 1200000.00   | 220000000000000 | 1.020000   | 1236 | 10200000000 |

### Usage

This data is used to build and refine the dynamic fee model for Fee Optimizer. By analyzing the trading volumes, liquidity, and gas prices, the model can adjust fees in real-time to ensure fair pricing and protect liquidity providers from impermanent loss.

## Mathematical Modeling Approaches

### Approach 1: Optimization Based on Volume, Liquidity, and Gas Price

#### Step 1: Define Variables
- Volume (V): The total volume of transactions.
- Liquidity (L): The available liquidity in the system.
- Gas Price (G): The current gas price for transactions.
- Fee (F): The dynamic fee to be determined.

#### Step 2: Establish Objective Function
The objective is to optimize the fee \( F \). Assume we want to maximize a revenue function \( R \), which is the product of fee and volume minus the cost associated with gas price and liquidity.

\( R = F \cdot V - C(G, L) \)

where \( C(G, L) \) is the cost function depending on gas price and liquidity.

#### Step 3: Define Cost Function
The cost function \( C(G, L) \) could be formulated as:

\( C(G, L) = a \cdot G + b \cdot \frac{1}{L} \)

where \( a \) and \( b \) are constants representing the sensitivity of the cost to gas price and liquidity, respectively.

#### Step 4: Constraints
- Non-negative fee: \( F \geq 0 \)
- Maximum fee: \( F \leq 0.1 \)
- Volume and liquidity relationship: \( V \leq k \cdot L \) (assuming volume is proportional to liquidity with a proportionality constant \( k \))

#### Step 5: Formulate the Optimization Problem
Objective:
\( \max_{F} \left( F \cdot V - \left( a \cdot G + b \cdot \frac{1}{L} \right) \right) \)

Subject to:
\( 0 \leq F \leq 0.1 \)
\( V \leq k \cdot L \)

#### Step 6: Implementing the Optimization
Using example values:

\( V = 1000 \)
\( L = 500 \)
\( G = 20 \)
\( a = 0.01 \)
\( b = 5 \)
\( k = 2 \)

The objective function simplifies to:
\( \max_{F} \left( 1000F - 0.21 \right) \)

With constraints:
\( 0 \leq F \leq 0.1 \)
\( 1000 \leq 1000 \) (which is true)

The optimal fee \( F \) in this simplified example is:
\( F = 0.1 \)
\( \max_{F} \left( 1000 \cdot 0.1 - 0.21 \right) = 99.79 \)

### Approach 2: Normalization-Based Dynamic Fee Calculation

The provided Python code snippet performs the following steps to calculate a dynamic fee based on normalized values of certain parameters:

#### Normalization of Columns:

- **Volume (in USD):** The column `volumeUSD` is normalized to a range between 0 and 1 using the formula:
  \[
  \text{volumeUSD\_norm} = \frac{\text{volumeUSD} - \min(\text{volumeUSD})}{\max(\text{volumeUSD}) - \min(\text{volumeUSD})}
  \]

- **Liquidity:** The column `liquidity` is similarly normalized:
  \[
  \text{liquidity\_norm} = \frac{\text{liquidity} - \min(\text{liquidity})}{\max(\text{liquidity}) - \min(\text{liquidity})}
  \]

- **Average Gas Price:** The column `avgGasPrice` is normalized:
  \[
  \text{avgGasPrice\_norm} = \frac{\text{avgGasPrice} - \min(\text{avgGasPrice})}{\max(\text{avgGasPrice}) - \min(\text{avgGasPrice})}
  \]

#### Dynamic Fee Calculation:

The dynamic fee is calculated by taking the average of the normalized values of `volumeUSD`, `liquidity`, and `avgGasPrice`:
\[
\text{dynamic\_fee} = \frac{\text{volumeUSD\_norm} + \text{liquidity\_norm} + \text{avgGasPrice\_norm}}{3}
\]

#### Scaling the Fee:

The calculated dynamic fee is then scaled to a range between 0 and 0.01 by multiplying it by 0.01:
\[
\text{dynamic\_fee} = \text{dynamic\_fee} \times 0.01
\]

#### Clipping the Fee:

Finally, to ensure the fee is within the desired range of (0, 0.01], any value exceeding 0.01 is clipped to 0.01:
\[
\text{dynamic\_fee} = \text{dynamic\_fee}.clip(\text{upper}=0.01)
\]

### Create API for Inference Math Model

To create an API for inferring the dynamic fee from our mathematical model, we can use Flask, a lightweight WSGI web application framework in Python. The API will take inputs like volume, liquidity, and gas price, and return the calculated dynamic fee.

#### Test the API

```bash
curl -X POST http://localhost:5000/calculate_fee \
    -H "Content-Type: application/json" \
    -d '{"volume": 1000, "liquidity": 500, "gas_price": 20}'
```

### Create Custom Adapter for API with Chainlink

To integrate the dynamic fee calculation API with Chainlink, we need to create a custom adapter. This adapter will act as a bridge between the Chainlink oracle and our Flask API. Here are the steps to create and deploy a custom adapter.

#### Step 1: Setup Chainlink Node

Ensure you have a running Chainlink node. Follow the [Chainlink documentation](https://docs.chain.link/docs/running-a-chainlink-node/) to set up your node.

#### Step 2: Create Custom Adapter

Create a new Node.js project for the custom adapter.


### Create and Deploy Smart Contracts (Sepolia) and Integrate with Chainlink Adapter

#### Step 1: Prepare Smart Contracts

You need to have three smart contracts: `AggregatorV3Interface.sol`, `MarketDataProvider.sol`, and `VolBasedDynamicFee.sol`.

#### Step 2: Deploy Smart Contracts





