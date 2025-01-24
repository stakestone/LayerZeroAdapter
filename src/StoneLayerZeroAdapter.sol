// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {OFTAdapter} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StoneLayerZeroAdapter is OFTAdapter {
    constructor(
        address _stone,
        address _lzEndpoint,
        address _delegate
    ) OFTAdapter(_stone, _lzEndpoint, _delegate) Ownable(_delegate) {}
}
