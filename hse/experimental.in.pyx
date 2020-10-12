import hse
from enum import Enum
from typing import Tuple, Optional
cimport hse_experimental
cimport hse_limits
from hse cimport hse
from libc.stdlib cimport free


class KvsPfxProbeCnt(Enum):
	"""
	@SUB@ experimental.KvsPfxProbeCnt.__doc__
	"""
	ZERO = hse_experimental.HSE_KVS_PFX_FOUND_ZERO
	ONE = hse_experimental.HSE_KVS_PFX_FOUND_ONE
	MUL = hse_experimental.HSE_KVS_PFX_FOUND_MUL


def kvdb_export(kvdb: hse.Kvdb, params: hse.Params, path: str) -> None:
	"""
	@SUB@ experimental.kvdb_export.__doc__
	"""
	cdef path_bytes = path.encode()
	cdef hse.hse_err_t err = hse_experimental.hse_kvdb_export_exp(kvdb._c_hse_kvdb, params._c_hse_params, <char *>path_bytes)
	if err != 0:
		raise hse.KvdbException(err)


def kvdb_import(mpool_name: str, path: str) -> None:
	"""
	@SUB@ experimental.kvdb_import.__doc__
	"""
	cdef mpool_name_bytes = mpool_name.encode()
	cdef path_bytes = path.encode()
	cdef hse.hse_err_t err = hse_experimental.hse_kvdb_import_exp(<char *>mpool_name_bytes, <char *>path_bytes)
	if err != 0:
		raise hse.KvdbException(err)


def kvs_prefix_probe(kvs: hse.Kvs, const unsigned char [:]pfx, unsigned char [:]key_buf=bytearray(hse_limits.HSE_KVS_KLEN_MAX), unsigned char [:]val_buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX), hse.KvdbTxn txn=None) -> Tuple[KvsPfxProbeCnt, Optional[bytes], Optional[bytes]]:
	"""
	@SUB@ experimental.kvs_prefix_probe.__doc__
	"""
	cnt, key, key_len, value, value_len = kvs_prefix_probe_with_lengths(kvs, pfx, key_buf, val_buf, txn)
	return (
		cnt,
		key[:key_len] if key and len(key) > key_len else key,
		value[:value_len] if value and len(value) > value_len else value
	)


def kvs_prefix_probe_with_lengths(kvs: hse.Kvs, const unsigned char [:]pfx, unsigned char [:]key_buf=bytearray(hse_limits.HSE_KVS_KLEN_MAX), unsigned char [:]val_buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX), hse.KvdbTxn txn=None) -> Tuple[KvsPfxProbeCnt, Optional[bytes], int, Optional[bytes], int]:
	"""
	@SUB@ experimental.kvs_prefix_probe_with_lengths.__doc__
	"""
	cdef const void *pfx_addr = NULL
	cdef size_t pfx_len = 0
	cdef hse_experimental.hse_kvs_pfx_probe_cnt found = hse_experimental.HSE_KVS_PFX_FOUND_ZERO
	cdef void *key_buf_addr = NULL
	cdef size_t key_buf_len = 0
	cdef size_t key_len = 0
	cdef void *val_buf_addr = NULL
	cdef size_t val_buf_len = 0
	cdef size_t val_len = 0
	if pfx is not None and len(pfx) > 0:
		pfx_addr = &pfx[0]
		pfx_len = len(pfx)
	if key_buf is not None and len(key_buf) > 0:
		key_buf_addr = &key_buf[0]
		key_buf_len = len(key_buf)
	if val_buf is not None and len(val_buf) > 0:
		val_buf_addr = &val_buf[0]
		val_buf_len = len(val_buf)
	cdef hse.hse_kvdb_opspec *opspec = hse.HSE_KVDB_OPSPEC_INIT() if txn else NULL
	if txn:
		opspec.kop_txn = txn._c_hse_kvdb_txn

	cdef hse.hse_err_t err = 0
	try:
		err = hse_experimental.hse_kvs_prefix_probe_exp(kvs._c_hse_kvs, opspec, pfx_addr, pfx_len, &found, key_buf_addr, key_buf_len, &key_len, val_buf_addr, val_buf_len, &val_len)
		if err != 0:
			raise hse.KvdbException(err)
		if found == hse_experimental.HSE_KVS_PFX_FOUND_ZERO:
			return found, None, 0, None, 0
	finally:
		if opspec:
			free(opspec)

	return KvsPfxProbeCnt.ZERO, bytes(key_buf), key_len, bytes(val_buf), val_len
