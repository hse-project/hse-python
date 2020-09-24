import errno
import os
from ctypes import c_int
from enum import Enum
from types import TracebackType
from typing import List, Optional, Tuple, Dict, Any, Iterator, Type
from libc.stdlib cimport calloc, free


# Thoughout these bindings, you will see C pointers be set to NULL after their
# destruction. Please continue to follow this pattern as the HSE C code does
# not do this. We use NULL checks to protect against double free
# issues within the python bindings.


KVDB_VERSION_STRING = hse_kvdb_version_string().decode()
KVDB_VERSION_TAG = hse_kvdb_version_tag().decode()
KVDB_VERSION_SHA = hse_kvdb_version_sha().decode()


class KvdbException(Exception):
	def __init__(self, hse_err_t returncode):
		self.returncode = hse_err_to_errno(returncode)
		self.message = os.strerror(self.returncode)

	def __str__(self):
		return self.message


cdef hse_kvdb_opspec *HSE_KVDB_OPSPEC_INIT():
	cdef hse_kvdb_opspec *opspec = <hse_kvdb_opspec *>calloc(1, sizeof(hse_kvdb_opspec))
	if not opspec:
		raise MemoryError()

	opspec.kop_opaque = 0xb0de0001

	return opspec


#cdef class KvdbCompactStatus:
#	cdef hse_kvdb_compact_status _c_hse_kvdb_compact_status
#
#	@property
#	def samp_lwm(self) -> unsigned int:
#		return self._c_hse_kvdb_compact_status.kvcs_samp_lwm
#
#	@property
#	def samp_hwm(self) -> unsigned int:
#		return self._c_hse_kvdb_compact_status.kvcs_samp_hwm
#
#	@property
#	def samp_curr(self) -> unsigned int:
#		return self._c_hse_kvdb_compact_status.kvcs_samp_curr
#
#	@property
#	def active(self) -> unsigned int:
#		return self._c_hse_kvdb_compact_status.kvcs_active
#
#	@property
#	def canceled(self) -> unsigned int:
#		return self._c_hse_kvdb_compact_status.kvcs_canceled


cdef class Kvdb:
	cdef hse_kvdb *_c_hse_kvdb

	def __cinit__(self):
		self._c_hse_kvdb = NULL

	def __dealloc__(self):
		pass

	def __enter__(self):
		return self

	def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
		self.close()

	def close(self):
		if not self._c_hse_kvdb:
			return

		cdef hse_err_t err = hse_kvdb_close(self._c_hse_kvdb)
		if err != 0:
			raise KvdbException(err)

	@staticmethod
	def init():
		cdef hse_err_t err = hse_kvdb_init()
		if err != 0:
			raise KvdbException(err)

	@staticmethod
	def fini():
		hse_kvdb_fini()

	@staticmethod
	def make(mp_name: str, Params params=None):
		cdef mp_name_bytes = mp_name.encode()
		cdef hse_params *p = params._c_hse_params if params else NULL

		cdef hse_err_t err = hse_kvdb_make(<char *>mp_name_bytes, p)
		if err != 0:
			raise KvdbException(err)

	@staticmethod
	def open(mp_name: str, Params params=None) -> Kvdb:
		cdef mp_name_bytes = mp_name.encode()
		cdef hse_params *p = params._c_hse_params if params else NULL

		kvdb = Kvdb()

		err = hse_kvdb_open(<char *>mp_name_bytes, p, &kvdb._c_hse_kvdb)
		if err != 0:
			raise KvdbException(err)
		if not kvdb._c_hse_kvdb:
			raise MemoryError()

		return kvdb

	def get_names(self) -> List[str]:
		cdef unsigned int count = 0
		cdef char **kvs_list = NULL
		cdef hse_err_t err = hse_kvdb_get_names(self._c_hse_kvdb, &count, &kvs_list)
		if err != 0:
			raise KvdbException(err)
		if count > 0 and not kvs_list:
			raise MemoryError()

		result = []
		for i in range(count):
			result.append(kvs_list[i].decode())

		hse_kvdb_free_names(self._c_hse_kvdb, kvs_list)

		return result

	def kvs_make(self, kvs_name: str, Params params=None):
		cdef kvs_name_bytes = kvs_name.encode()
		cdef hse_params *p = params._c_hse_params if params else NULL

		cdef hse_err_t err = hse_kvdb_kvs_make(self._c_hse_kvdb, <char *>kvs_name_bytes, p)
		if err != 0:
			raise KvdbException(err)

	def kvs_drop(self, kvs_name: str):
		cdef kvs_name_bytes = kvs_name.encode()
		cdef hse_err_t err = hse_kvdb_kvs_drop(self._c_hse_kvdb, <char *>kvs_name_bytes)
		if err != 0:
			raise KvdbException(err)

	def kvs_open(self, kvs_name: str, Params params=None) -> Kvs:
		cdef hse_params *p = params._c_hse_params if params else NULL
		cdef kvs_name_bytes = kvs_name.encode()

		kvs = Kvs()

		cdef hse_err_t err = hse_kvdb_kvs_open(self._c_hse_kvdb, <char *>kvs_name_bytes, p, &kvs._c_hse_kvs)
		if err != 0:
			raise KvdbException(err)
		if not kvs._c_hse_kvs:
			raise MemoryError()

		return kvs

	def sync(self):
		cdef hse_err_t err = hse_kvdb_sync(self._c_hse_kvdb)
		if err != 0:
			raise KvdbException(err)

	def flush(self):
		cdef hse_err_t err = hse_kvdb_flush(self._c_hse_kvdb)
		if err != 0:
			raise KvdbException(err)

	def compact(self, cancel=False, samp_lwm=False):
		cdef int flags = 0
		if cancel:
			flags |= HSE_KVDB_COMP_FLAG_CANCEL
		if samp_lwm:
			flags |= HSE_KVDB_COMP_FLAG_SAMP_LWM

		cdef hse_err_t err = hse_kvdb_compact(self._c_hse_kvdb, flags)
		if err != 0:
			raise KvdbException(err)

	#def compact_status(self):
	#	status = KvdbCompactStatus()
	#	cdef hse_err_t err = hse_kvdb_compact_status(self._c_hse_kvdb, &status._c_hse_kvdb_compact_status)
	#	if err != 0:
	#		raise KvdbException(err)

	def txn_alloc(self) -> KvdbTxn:
		return KvdbTxn(self)


cdef class Kvs:
	cdef hse_kvs *_c_hse_kvs

	def __cinit__(self):
		pass

	def __dealloc__(self):
		pass

	def __enter__(self):
		return self

	def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
		self.close()

	def close(self):
		if not self._c_hse_kvs:
			return

		cdef hse_err_t err = hse_kvdb_kvs_close(self._c_hse_kvs)
		if err != 0:
			raise KvdbException(err)

	def put(self, const unsigned char [:]key, const unsigned char [:]val, priority=False, KvdbTxn txn=None):
		cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if priority or txn else NULL
		if priority:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_PRIORITY
		if txn:
			opspec.kop_txn = txn._c_hse_kvdb_txn

		cdef hse_err_t err = 0
		try:
			err = hse_kvs_put(self._c_hse_kvs, opspec, &key[0], len(key), &val[0], len(val))
			if err != 0:
				raise KvdbException(err)
		finally:
			if opspec:
				free(opspec)

	def get(self, const unsigned char [:]key, KvdbTxn txn=None, const unsigned char [:]buf=bytearray(1024 * 1024)) -> Optional[bytes]:
		cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if txn else NULL
		if txn:
			opspec.kop_txn = txn._c_hse_kvdb_txn

		cdef bool found = False
		cdef size_t val_len = 0
		cdef hse_err_t err = 0
		try:
			err = hse_kvs_get(self._c_hse_kvs, opspec, &key[0], len(key), &found, <void *>&buf[0], len(buf), &val_len)
			if err != 0:
				raise KvdbException(err)
			if not found:
				return None
		finally:
			if opspec:
				free(opspec)

		return bytes(buf[:val_len])

	def delete(self, const unsigned char [:]key, priority=False, KvdbTxn txn=None):
		cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if priority or txn else NULL
		if priority:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_PRIORITY
		if txn:
			opspec.kop_txn = txn._c_hse_kvdb_txn

		cdef hse_err_t err = 0
		try:
			err = hse_kvs_delete(self._c_hse_kvs, opspec, &key[0], len(key))
			if err != 0:
				raise KvdbException(err)
		finally:
			free(opspec)

	def prefix_delete(self, const unsigned char [:]filt, priority=False, KvdbTxn txn=None):
		cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if priority or txn else NULL
		if priority:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_PRIORITY
		if txn:
			opspec.kop_txn = txn._c_hse_kvdb_txn

		cdef hse_err_t err = 0
		try:
			err = hse_kvs_prefix_delete(self._c_hse_kvs, opspec, &filt[0], len(filt), NULL)
			if err != 0:
				raise KvdbException(err)
		finally:
			if opspec:
				free(opspec)

	def cursor_create(
        self,
        const unsigned char [:]filt=None,
        reverse=False,
        static_view=False,
		bind_txn=False,
		KvdbTxn txn=None
    ):
		cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if reverse or static_view or bind_txn or txn else NULL

		if reverse:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_REVERSE
		if static_view:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_STATIC_VIEW
		if bind_txn:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_BIND_TXN
		if txn:
			opspec.kop_txn = txn._c_hse_kvdb_txn

		cursor = KvsCursor()

		cdef hse_err_t err = 0
		try:
			if len(filt) != 0:
				err = hse_kvs_cursor_create(
					self._c_hse_kvs,
					opspec,
					&filt[0],
					len(filt),
					&cursor._c_hse_kvs_cursor
				)
			else:
				err = hse_kvs_cursor_create(
					self._c_hse_kvs,
					opspec,
					NULL,
					0,
					&cursor._c_hse_kvs_cursor
				)

			if err != 0:
				raise KvdbException(err)
		finally:
			if opspec:
				free(opspec)

		return cursor


class KvdbTxnState(Enum):
	INVALID = HSE_KVDB_TXN_INVALID
	ACTIVE = HSE_KVDB_TXN_ACTIVE
	COMMITTED = HSE_KVDB_TXN_COMMITTED
	ABORTED = HSE_KVDB_TXN_ABORTED


cdef class KvdbTxn:
	cdef hse_kvdb_txn *_c_hse_kvdb_txn
	cdef hse_kvdb *_c_hse_kvdb

	def __cinit__(self, kvdb: Kvdb):
		self._c_hse_kvdb = kvdb._c_hse_kvdb
		self._c_hse_kvdb_txn = hse_kvdb_txn_alloc(self._c_hse_kvdb)
		if not self._c_hse_kvdb_txn:
			raise MemoryError()

	def __dealloc__(self):
		if not self._c_hse_kvdb:
			return
		if not self._c_hse_kvdb_txn:
			return

		hse_kvdb_txn_free(self._c_hse_kvdb, self._c_hse_kvdb_txn)
		self._c_hse_kvdb_txn = NULL

	def __enter__(self):
		self.begin()
		return self

	def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
		# PEP-343: If exception occurred in with statement, abort transaction
		if exc_tb:
			self.abort()

		if self.get_state() == KvdbTxnState.ACTIVE:
			self.commit()

	def begin(self):
		cdef hse_err_t err = hse_kvdb_txn_begin(self._c_hse_kvdb, self._c_hse_kvdb_txn)
		if err != 0:
			raise KvdbException(err)

	def commit(self):
		cdef hse_err_t err = hse_kvdb_txn_commit(self._c_hse_kvdb, self._c_hse_kvdb_txn)
		if err != 0:
			raise KvdbException(err)

	def abort(self):
		cdef hse_err_t err = hse_kvdb_txn_abort(self._c_hse_kvdb, self._c_hse_kvdb_txn)
		if err != 0:
			raise KvdbException(err)

	def get_state(self) -> KvdbTxnState:
		return KvdbTxnState(hse_kvdb_txn_get_state(self._c_hse_kvdb, self._c_hse_kvdb_txn))


cdef class KvsCursor:
	cdef hse_kvs_cursor* _c_hse_kvs_cursor

	def __cinit__(self):
		self._c_hse_kvs_cursor

	def __dealloc__(self):
		if self._c_hse_kvs_cursor:
			hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)
			self._c_hse_kvs_cursor = NULL

	def __enter__(self):
		return self

	def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
		self.destroy()

	def destroy(self):
		if self._c_hse_kvs_cursor:
			hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)
			self._c_hse_kvs_cursor = NULL

	def items(self, max_count=None) -> Iterator[Tuple[bytes, Optional[bytes]]]:
		"""Convenience function to return a generator"""
		def _iter():
			count = 0

			while True:
				if max_count and count > max_count:
					return

				count += 1
				key, val, eof = self.read()
				if not eof:
					yield key, val
				else:
					self.destroy()
					return

		return _iter()

	def update(self, reverse=None, static_view=None, bind_txn=None, KvdbTxn txn=None):
		if reverse is None and static_view is None and bind_txn is None and txn is None:
			return

		cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if reverse is not None or static_view is not None or bind_txn is not None or txn is not None else NULL

		if reverse:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_REVERSE
		if static_view:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_STATIC_VIEW
		if bind_txn:
			opspec.kop_flags |= HSE_KVDB_KOP_FLAG_BIND_TXN
		if txn:
			opspec.kop_txn = txn._c_hse_kvdb_txn

		cdef hse_err_t err = 0
		try:
			err = hse_kvs_cursor_update(self._c_hse_kvs_cursor, opspec)
			if err != 0:
				raise KvdbException(err)
		finally:
			if opspec:
				free(opspec)

	def seek(self, const unsigned char [:]key) -> Optional[bytes]:
		cdef const void *found = NULL
		cdef size_t found_len = 0
		cdef hse_err_t err = hse_kvs_cursor_seek(
			self._c_hse_kvs_cursor,
			NULL,
			&key[0],
			len(key),
			&found,
			&found_len
		)
		if err != 0:
			raise KvdbException(err)

		if not found:
			return None

		return bytes((<char *>found)[:found_len])

	def seek_range(self, const unsigned char [:]filt_min, const unsigned char [:]filt_max) -> Optional[bytes]:
		cdef const void *found = NULL
		cdef size_t found_len = 0
		cdef hse_err_t err = hse_kvs_cursor_seek_range(
			self._c_hse_kvs_cursor,
			NULL,
			&filt_min[0],
			len(filt_min),
			&filt_max[0],
			len(filt_max),
			&found,
			&found_len
		)
		if err != 0:
			raise KvdbException(err)

		if not found:
			return None

		return (<char *>found)[:found_len]

	# Compiler error when using Tuple[bytes, Optional[bytes], bool/bint]
	# When we move to Python >= 3.8, use
	# Tuple[bytes, bytes, Union[Literal[True], Literal[False]]] as a workaround
	def read(self) -> tuple:
		cdef const void *key = NULL
		cdef const void *val = NULL
		cdef size_t key_len = 0
		cdef size_t val_len = 0
		cdef bool eof = False
		cdef hse_err_t err = hse_kvs_cursor_read(
			self._c_hse_kvs_cursor,
			NULL,
			&key,
			&key_len,
			&val,
			&val_len,
			&eof
		)
		if err != 0:
			raise KvdbException(err)

		if eof:
			return None, None, True
		else:
			return (<char*>key)[:key_len], (<char*>val)[:val_len] if val else None, False


cdef class Params:
	cdef hse_params *_c_hse_params

	def __cinit__(self):
		self._c_hse_params = NULL

	def __dealloc__(self):
		if self._c_hse_params:
			hse_params_destroy(self._c_hse_params)
			self._c_hse_params = NULL

	def __getitem__(self, key) -> Optional[str]:
		return self.get(key)

	def __setitem__(self, key, value):
		self.set(key, value)

	def set(self, key: str, value: str):
		if not self._c_hse_params:
			return

		hse_params_set(self._c_hse_params, key.encode(), value.encode())

	# 256 comes from hse_params.c HP_DICT_LET_MAX
	def get(self, key: str, char [:]buf=bytearray(256)) -> Optional[str]:
		if not self._c_hse_params:
			return None

		return hse_params_get(self._c_hse_params, key, &buf[0], 256, NULL).decode()

	@staticmethod
	def create() -> Params:
		p = Params()

		cdef hse_err_t err = hse_params_create(&p._c_hse_params)
		if err == errno.ENOMEM:
			raise MemoryError()
		if err != 0:
			raise KvdbException(err)

		return p

	@staticmethod
	def from_dict(params: Dict[str, str]) -> Params:
		p = Params()

		input = ",".join(map(lambda t: f"{t[0]}={t[1]}", params.items())).encode()
		cdef int err = hse_params_from_string(p._c_hse_params, <char *>input)
		if err == errno.ENOMEM:
			raise MemoryError()
		if err != 0:
			raise KvdbException(err)

		return p

	@staticmethod
	def from_file(path: str) -> Params:
		cdef path_bytes = path.encode()

		p = Params()

		cdef int err = hse_params_from_file(p._c_hse_params, <char *>path_bytes)
		if err == errno.ENOMEM:
			raise MemoryError()
		if err != 0:
			raise KvdbException(err)

		return p

	@staticmethod
	def from_string(input: str) -> Params:
		cdef input_bytes = input.encode()

		p = Params()

		cdef int err = hse_params_from_string(p._c_hse_params, <char *>input_bytes)

		if err == errno.ENOMEM:
			raise MemoryError()
		if err != 0:
			raise KvdbException(err)

		return p
