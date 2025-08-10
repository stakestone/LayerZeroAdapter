// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {OFTAdapter} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

contract CommonLayerZeroAdapter is OFTAdapter, AccessControl {
    bytes32 public constant CAP_SETTER_ROLE = keccak256("CAP_SETTER_ROLE");
    uint256 public cap;
    mapping(uint256 => uint256) public quota;

    event CapSet(uint256 beforeCap, uint256 afterCap);

    constructor(
        address _token,
        address _lzEndpoint,
        address _delegate,
        uint256 _cap
    ) OFTAdapter(_token, _lzEndpoint, _delegate) Ownable(_delegate) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        cap = _cap;
        emit CapSet(0, _cap);
    }

    function setCap(uint256 _cap) external onlyRole(CAP_SETTER_ROLE) {
        emit CapSet(cap, _cap);
        cap = _cap;
    }

    function getQuota() external view returns (uint256) {
        uint256 amount = quota[block.timestamp / 1 days];
        if (cap > amount) {
            return cap - amount;
        } else {
            return 0;
        }
    }

    function approvalRequired() external pure virtual override returns (bool) {
        return false;
    }

    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    )
        internal
        virtual
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(
            _amountLD,
            _minAmountLD,
            _dstEid
        );

        uint256 day = block.timestamp / 1 days;
        quota[day] = quota[day] + amountSentLD;
        require(quota[day] <= cap, "Cap Reached");

        IToken(address(innerToken)).burn(_from, amountSentLD);
    }

    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 /*_srcEid*/
    ) internal virtual override returns (uint256 amountReceivedLD) {
        IToken(address(innerToken)).mint(_to, _amountLD);
        return _amountLD;
    }
}
