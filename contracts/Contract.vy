# @version 0.1.0b16
# @notice Implementation of Lendroid protocol - LeaseERC721
# @dev THIS CONTRACT HAS NOT BEEN AUDITED
# Lendroid Foundation


from ...interfaces import ERC721Interface


# @private
# def _to_f_and_i(_currency: address, _expiry: timestamp,
#     _value: uint256, _from: address, _to: address):
#     _l_address: address = ZERO_ADDRESS
#     _i_address: address = ZERO_ADDRESS
#     _f_address: address = ZERO_ADDRESS
#     _s_address: address = ZERO_ADDRESS
#     _u_address: address = ZERO_ADDRESS
#     _l_address, _i_address, _f_address, _s_address, _u_address = CurrencyDaoInterface(self.daos[DAO_CURRENCY]).mft_addresses(_currency)
#     _i_id: uint256 = MultiFungibleTokenInterface(_i_address).get_or_create_id(_currency, _expiry, ZERO_ADDRESS, 0, "")
#     _f_id: uint256 = MultiFungibleTokenInterface(_f_address).get_or_create_id(_currency, _expiry, ZERO_ADDRESS, 0, "")
#     assert (not _i_id == 0) and (not _f_id == 0)
#     # burn l_token from _from account
#     assert_modifiable(CurrencyDaoInterface(self.daos[DAO_CURRENCY]).burn_as_self_authorized_erc20(_l_address, _from, _value))
#     if _expiry > block.timestamp:
#         # mint i_token into _to account
#         assert_modifiable(MultiFungibleTokenInterface(_i_address).mint(_i_id, _to, _value))
#     # mint f_token into _to account
#     assert_modifiable(MultiFungibleTokenInterface(_f_address).mint(_f_id, _to, _value))
#
#
# @public
# def split(_currency: address, _expiry: timestamp, _value: uint256) -> bool:
#     assert self.initialized
#     assert not self.paused
#     assert CurrencyDaoInterface(self.daos[DAO_CURRENCY]).is_token_supported(_currency)
#     self._to_f_and_i(_currency, _expiry, _value, msg.sender, msg.sender)
#
#     return True
#
#
# @private
# def _from_f_and_i(_currency: address, _expiry: timestamp,
#     _value: uint256, _from: address, _to: address):
#     _l_address: address = ZERO_ADDRESS
#     _i_address: address = ZERO_ADDRESS
#     _f_address: address = ZERO_ADDRESS
#     _s_address: address = ZERO_ADDRESS
#     _u_address: address = ZERO_ADDRESS
#     _l_address, _i_address, _f_address, _s_address, _u_address = CurrencyDaoInterface(self.daos[DAO_CURRENCY]).mft_addresses(_currency)
#     _i_id: uint256 = MultiFungibleTokenInterface(_i_address).id(_currency, _expiry, ZERO_ADDRESS, 0)
#     _f_id: uint256 = MultiFungibleTokenInterface(_f_address).id(_currency, _expiry, ZERO_ADDRESS, 0)
#     assert (not _i_id == 0) and (not _f_id == 0)
#     if _expiry > block.timestamp:
#         # burn i_token from _from account
#         assert_modifiable(MultiFungibleTokenInterface(_i_address).burn(_i_id, _from, _value))
#     # burn f_token from _from account
#     assert_modifiable(MultiFungibleTokenInterface(_f_address).burn(_f_id, _from, _value))
#     # mint l_token into _to account
#     assert_modifiable(CurrencyDaoInterface(self.daos[DAO_CURRENCY]).mint_and_self_authorize_erc20(_l_address, _to, _value))
#
#
# @public
# def fuse(_currency: address, _expiry: timestamp, _value: uint256) -> bool:
#     assert self.initialized
#     assert not self.paused
#     assert CurrencyDaoInterface(self.daos[DAO_CURRENCY]).is_token_supported(_currency)
#     self._from_f_and_i(_currency, _expiry, _value, msg.sender, msg.sender)
#
#     return True
