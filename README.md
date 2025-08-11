# Ethernaut

> **CTF-style smart contract hacking challenges.**
> 
> This repo contains solutions and explanations for Ethernaut levels. Each branch corresponds to a different level.

## 🪙 Level 2: Fallback

### Overview

This challenge demonstrates how improper use of the `receive()` function and weak access control can allow attackers to take ownership of a contract and drain its funds.

The Fallback contract allows:
- Users to contribute small amounts of Ether.
- Ownership transfer to contributors who exceed the current owner’s contribution.
- Receiving Ether via `receive()` to also set the sender as the owner (if they have contributed before).

**Goal:** Become the owner of the contract and withdraw all funds.

---

### 🔍 Vulnerability Analysis

- **Weak Ownership Logic:**
  - Ownership can be reassigned if:
    - You send Ether directly to the contract using `receive()` **and**
    - You already have a non-zero contribution.
- **Lack of Proper Access Control:**
  - The `receive()` function is not protected by `onlyOwner`, so any contributor can trigger it to become the owner.
- **No Minimum Threshold for Ownership Transfer via receive():**
  - Any amount of Ether (>0) is enough to change the owner after a contribution.

---

### 🛠️ Exploitation Steps

1. **Make a Small Contribution**
   
   You must first contribute to have `contributions[msg.sender] > 0`:
   
   ```js
   await contract.contribute({ value: toWei("0.0000000000001") });
   await contract.getContribution(); // should be > 0
   ```

2. **Trigger `receive()` to Become Owner**
   
   Send Ether outside the ABI (direct transaction) to the contract address:
   
   ```js
   await contract.sendTransaction({
     to: "0xDBEBD77F08559597e2c4DA23520ca5603e151C66", // contract address
     value: toWei("0.0000000000001")
   });
   ```
   Now the `receive()` function runs and sets you as owner.

3. **Verify Ownership**
   
   ```js
   await contract.owner();
   // should return your wallet address
   ```

4. **Withdraw All Funds**
   
   ```js
   await contract.withdraw();
   ```
   All Ether in the contract is now transferred to your address.

---

### 🪲 Root Cause

The vulnerability stems from allowing state changes in `receive()` without proper access control.

> **Best practice:** Use `receive()` only for accepting Ether, not changing contract ownership.

---

### 🛡️ Prevention

- Never change ownership in `receive()` or `fallback()`.
- Use strict access control (`onlyOwner` or similar modifiers).
- Avoid logic in `receive()` that can be abused by anyone sending Ether.

---

## 🪙 Level 4: Coin Flip

### Vulnerable Contract & Problem

The original contract determines the coin flip outcome using:

```solidity
uint256 coinFlip = uint256(blockhash(block.number - 1)) / FACTOR;
```

- `blockhash(block.number - 1)` is publicly available, so anyone can predict the outcome before calling the function.
- `FACTOR` is a constant that makes `coinFlip` either 0 or 1.
- **Result:** The randomness is fully deterministic and predictable.

---

### 💥 Exploit Strategy

1. Read the blockchain’s last block hash using the same formula as the contract.
2. Calculate the expected outcome (`true` or `false`).
3. Submit the guess to the contract.
4. Repeat for 10 consecutive wins to complete the challenge.

---

## 🛠️ Hack Contract (FlipCoin Branch)

### 🔑 How the Hack Works

- The Hack contract imports the vulnerable CoinFlip contract.
- `_guess()` replicates the calculation from the original contract.
- Both contracts run in the same transaction, sharing the same `block.number` and `blockhash`, ensuring the prediction is always correct.
- By calling `flip()` every block, the attacker gets a 100% win rate.

---

## ⚠️ Security Lessons

- On-chain randomness is **not secure** if it relies on predictable values like `blockhash` or `block.timestamp`.
- Use [Chainlink VRF](https://docs.chain.link/vrf/v2/introduction/) or other verifiable randomness oracles for secure random numbers.
- Never assume miners won't manipulate predictable variables—they can influence them.

---

## ✅ Steps to Reproduce the Hack

1. Deploy the CoinFlip contract (from the challenge).
2. Deploy the Hack contract with the address of the deployed CoinFlip contract.
3. Call `flip()` from the Hack contract once per block for 10 blocks.
4. `consecutiveWins` will reach 10, completing the challenge.