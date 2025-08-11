# Ethernaut

> **CTF-style smart contract hacking challenges.**
> 
> This repo contains solutions and explanations for Ethernaut levels. Each branch corresponds to a different level.

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