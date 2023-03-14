// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {ICheqModule} from "../interfaces/ICheqModule.sol";
import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

/**
 * Note: Only payments, allows sender to choose when to release and whether to reverse (assuming it's not released yet)
 */
contract ReversableTimelock is ModuleBase {
    struct Payment {
        address inspector;
        address drawer;
        uint256 inspectionEnd;
        bytes32 memoHash;
    }
    mapping(uint256 => Payment) public payments;

    constructor(
        address registrar,
        DataTypes.WTFCFees memory _fees,
        string memory __baseURI
    ) ModuleBase(registrar, _fees) {
        _URI = __baseURI;
    }

    function _collectFee(
        uint256 escrowed,
        uint256 instant,
        address currency,
        address dappOperator
    ) internal returns (uint256 moduleFee) {
        uint256 totalAmount = escrowed + instant;
        moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
        revenue[dappOperator][currency] += moduleFee;
    }

    function processWrite(
        address caller,
        address owner,
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        (
            address inspector,
            uint256 inspectionEnd,
            address dappOperator,
            bytes32 memoHash
        ) = abi.decode(initData, (address, uint256, address, bytes32));
        require((caller != owner) && (owner != address(0)), "Invalid Params");

        payments[cheqId].inspector = inspector;
        payments[cheqId].inspectionEnd = inspectionEnd;
        payments[cheqId].drawer = caller;
        payments[cheqId].memoHash = memoHash;

        return _collectFee(escrowed, instant, currency, dappOperator);
    }

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address /*from*/,
        address /*to*/,
        uint256 /*cheqId*/,
        address currency,
        uint256 escrowed,
        uint256 /*createdAt*/,
        bytes memory /*data*/
    ) external override onlyRegistrar returns (uint256) {
        require(
            caller == owner || caller == approved,
            "Only owner or approved"
        );
        return _collectFee(escrowed, 0, currency, REGISTRAR);
    }

    function processFund(
        address, // caller,
        address, // owner,
        uint256, // amount,
        uint256, // instant,
        uint256, // cheqId,
        DataTypes.Cheq calldata, // cheq,
        bytes calldata // initData
    ) external view override onlyRegistrar returns (uint256) {
        require(false, "");
        return 0;
    }

    function processCash(
        address caller,
        address /*owner*/,
        address /*to*/,
        uint256 amount,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        require(
            caller == payments[cheqId].inspector,
            "Inspector cash for owner"
        );
        return
            _collectFee(
                0,
                amount,
                cheq.currency,
                abi.decode(initData, (address))
            );
    }

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes memory initData
    ) external override onlyRegistrar {}

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        return
            bytes(_URI).length > 0
                ? string(abi.encodePacked(_URI, tokenId))
                : "";
        // return string(abi.encode(_URI, payments[tokenId].memoHash));
    }
}
