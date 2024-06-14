## About

This repository implements multichain Super Tokens.  
For more details about how to build such _Custom Super Tokens_, see https://github.com/superfluid-finance/protocol-monorepo/wiki/About-Custom-Super-Token

### xERC20

[xERC20](https://www.xerc20.com/) is a bridge-agnostic protocol which allows token issuers to _deploy crosschain native tokens with zero slippage, perfect fungibility, and granular risk settings — all while maintaining ownership of your token contracts._.

[BridgedSuperToken.sol](src/BridgedSuperToken.sol) implements a [Pure Super Token](https://docs.superfluid.finance/docs/protocol/super-tokens/overview#2-pure-super-tokens) with xERC20.  
The core functions are `mint` and `burn`. They leverage the hooks `selfMint` and `selfBurn` provided by the stock Super Token implementation.  
The rest of the logic is mostly about setting and enforcing rate limits per bridge. The limits are defined as the maximum token amount a bridge can mint or burn per 24 hours (rolling time window).

### Optimism / Superchain Standard Bridge

L2's based on the OP / Superchain stack can use the native [Standard Bridge](https://docs.optimism.io/builders/app-developers/bridging/standard-bridge) for maximum security.

[OPBridgedSuperToken.sol](src/OPBridgedSuperToken.sol) allows that by implementing the required ´IOptimismMintableERC20` interface.  
Its `mint()` and `burn()` match those of IXERC20, but it adds `bridge()` (address of the bridge contract), `remoteToken()` (address of the token on L1) and `supportsInterface()` (ERC165 interface detection).

### HomeERC20

Is a plain OpenZeppelin based ERC20 with ERC20Votes extension.  
Suitable for multichain tokens which want an ERC20 representation on L1 and Super Token representations on L2s.

## Build & Deploy

In order build the contracts, you need `forge` installed, see https://getfoundry.sh/.

After cloning the repository, do
`forge install`. Then you can compile the contracts with `forge compile` or run tests with `forge test`.

In order to deploy a multichain Super Token to a [Superfluid supported chain]([https://console.superfluid.finance/protocol](https://github.com/superfluid-finance/protocol-monorepo/blob/dev/packages/metadata/networks.json)), you can use the convenience script [deploy.sh](./deploy.sh).  
Look into the script in order to learn about supported arguments and env vars.

Example use:
```
PRIVKEY=xyz... OWNER=0x... NAME="My Token" SYMBOL="MTK" INITIAL_SUPPLY=0 ./deploy.sh L2 optimism-sepolia
```
