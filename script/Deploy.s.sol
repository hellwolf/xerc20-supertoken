// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import { ISuperTokenFactory } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { BridgedSuperTokenProxy, IBridgedSuperToken } from "../src/BridgedSuperToken.sol";
import { OPBridgedSuperTokenProxy, IOPBridgedSuperToken } from "../src/OPBridgedSuperToken.sol";
import { HomeERC20 } from "../src/HomeERC20.sol";

/// abstract base contract to avoid code duplication
abstract contract DeployBase is Script {
    uint256 deployerPrivKey;
    address owner;
    string name;
    string symbol;
    uint256 initialSupply;

    function _loadEnv() internal virtual {
        deployerPrivKey = vm.envUint("PRIVKEY");
        owner = vm.envAddress("OWNER");
        name = vm.envString("NAME");
        symbol = vm.envString("SYMBOL");
        initialSupply = vm.envUint("INITIAL_SUPPLY");
    }
}

/// deploys an instance of HomeERC20
contract DeployL1Token is DeployBase {
    function run() external {
        _loadEnv();

        vm.startBroadcast(deployerPrivKey);

        // log params
        console.log("Deploying ERC20 with params:");
        console.log("  name:", name);
        console.log("  symbol:", symbol);
        console.log("  initialSupply:", initialSupply);
        console.log("  owner:", owner);

        // since the token is permissionless and non-upgradable, the "owner" doesn't
        // own the contract, just the initial supply
        HomeERC20 erc20 = new HomeERC20(name, symbol, owner, initialSupply);
        console.log("ERC20 deployed at", address(erc20));

        vm.stopBroadcast();
    }
}

/// deploys and initializes an instance of BridgedSuperTokenProxy
contract DeployL2Token is DeployBase {
    function run() external {
        _loadEnv();

        address superTokenFactoryAddr = vm.envAddress("SUPERTOKEN_FACTORY");

        vm.startBroadcast(deployerPrivKey);

        BridgedSuperTokenProxy proxy = new BridgedSuperTokenProxy();
        proxy.initialize(ISuperTokenFactory(superTokenFactoryAddr), name, symbol, owner, initialSupply);
        proxy.transferOwnership(owner);
        console.log("BridgedSuperTokenProxy deployed at", address(proxy));

        vm.stopBroadcast();
    }
}

/// deploys and initializes an instance of OPBridgedSuperTokenProxy
contract DeployOPToken is DeployBase {
    function run() external {
        _loadEnv();

        vm.startBroadcast(deployerPrivKey);

        address superTokenFactoryAddr = vm.envAddress("SUPERTOKEN_FACTORY");
        address nativeBridge = vm.envAddress("NATIVE_BRIDGE");
        address remoteToken = vm.envAddress("REMOTE_TOKEN");

        OPBridgedSuperTokenProxy proxy = new OPBridgedSuperTokenProxy(nativeBridge, remoteToken);
        proxy.initialize(ISuperTokenFactory(superTokenFactoryAddr), name, symbol, owner, initialSupply);
        proxy.transferOwnership(owner);
        console.log("OPBridgedSuperTokenProxy deployed at", address(proxy));

        vm.stopBroadcast();
    }
}