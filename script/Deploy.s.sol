// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import { ISuperTokenFactory } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { BridgedSuperTokenProxy, IBridgedSuperToken } from "../src/BridgedSuperToken.sol";
import { OPBridgedSuperTokenProxy, IOPBridgedSuperToken } from "../src/OPBridgedSuperToken.sol";
import { HomeERC20 } from "../src/HomeERC20.sol";

/// abstract base contract to avoid code duplication
abstract contract DeployBase is Script {
    address owner;
    string name;
    string symbol;
    uint256 initialSupply;

    function _startBroadcast() internal returns (address deployer) {
        uint256 deployerPrivKey = vm.envOr("PRIVKEY", uint256(0));

        // Setup deployment account, using private key from environment variable or foundry keystore (`cast wallet`).
        if (deployerPrivKey != 0) {
            vm.startBroadcast(deployerPrivKey);
        } else {
            vm.startBroadcast();
        }

        // This is the way to get deployer address in foundry:
        (,deployer,) = vm.readCallers();
        console2.log("Deployer address", deployer);
    }

    function _stopBroadcast() internal {
        vm.stopBroadcast();
    }

    function _showGitRevision() internal {
        string[] memory inputs = new string[](2);
        inputs[0] = "./tasks/show-git-rev.sh";
        inputs[1] = "forge_ffi_mode";
        try vm.ffi(inputs) returns (bytes memory res) {
            console.log("Git revision: %s", string(res));
        } catch {
            console.log("!! _showGitRevision: FFI not enabled");
        }
    }

    function _loadTokenParams(string memory tokenType) internal virtual {
        owner = vm.envAddress("OWNER");
        name = vm.envString("NAME");
        symbol = vm.envString("SYMBOL");
        initialSupply = vm.envUint("INITIAL_SUPPLY");

        console.log("Deploying \"%s\" with params:", tokenType);
        console.log("  owner:", owner);
        console.log("  name:", name);
        console.log("  symbol:", symbol);
        console.log("  initialSupply:", initialSupply);
    }
}

/// deploys an instance of HomeERC20
contract DeployL1Token is DeployBase {
    function run() external {
        _showGitRevision();
        _loadTokenParams("Home ERC20");

        _startBroadcast();

        // since the token is permissionless and non-upgradable, the "owner" doesn't
        // own the contract, just the initial supply
        HomeERC20 erc20 = new HomeERC20(name, symbol, owner, initialSupply);
        console.log("ERC20 deployed at", address(erc20));

        _stopBroadcast();
    }
}

/// deploys and initializes an instance of BridgedSuperTokenProxy
contract DeployL2Token is DeployBase {
    function run() external {
        _showGitRevision();
        _loadTokenParams("Regular Bridged Super Token");

        address superTokenFactoryAddr = vm.envAddress("SUPERTOKEN_FACTORY");

        _startBroadcast();

        BridgedSuperTokenProxy proxy = new BridgedSuperTokenProxy();
        proxy.initialize(ISuperTokenFactory(superTokenFactoryAddr), name, symbol, owner, initialSupply);
        proxy.transferOwnership(owner);
        console.log("BridgedSuperTokenProxy deployed at", address(proxy));
        console.log("  superTokenFactory: %s", superTokenFactoryAddr);

        _stopBroadcast();
    }
}

/// deploys and initializes an instance of OPBridgedSuperTokenProxy
contract DeployOPToken is DeployBase {
    function run() external {
        _showGitRevision();
        _loadTokenParams("OP Bridged Super Token");

        _startBroadcast();

        address superTokenFactoryAddr = vm.envAddress("SUPERTOKEN_FACTORY");
        address nativeBridge = vm.envAddress("NATIVE_BRIDGE");
        address remoteToken = vm.envAddress("REMOTE_TOKEN");

        OPBridgedSuperTokenProxy proxy = new OPBridgedSuperTokenProxy(nativeBridge, remoteToken);
        proxy.initialize(ISuperTokenFactory(superTokenFactoryAddr), name, symbol, owner, initialSupply);
        proxy.transferOwnership(owner);
        console.log("OPBridgedSuperTokenProxy deployed at", address(proxy));
        console.log("  superTokenFactory: %s", superTokenFactoryAddr);
        console.log("  nativeBridge: %s", nativeBridge);
        console.log("  remoteToken: %s", remoteToken);

        _stopBroadcast();
    }
}
