# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2022 Micron Technology, Inc. All rights reserved.

import os
import pathlib
from collections.abc import Iterator
from enum import Enum, IntEnum, IntFlag, unique
from types import TracebackType
from typing import List, Optional, SupportsBytes, Tuple, Type, Union

def init(config: Optional[Union[str, os.PathLike[str]]] = ..., *params: str) -> None:
    """
    @SUB@ hse.init
    """
    ...

def fini() -> None:
    """
    @SUB@ hse.fini
    """
    ...

def param(param: str) -> str:
    """
    @SUB@ hse.param
    """
    ...

@unique
class ErrCtx(IntEnum):
    """
    @SUB@ hse.ErrCtx
    """

    NONE = ...

class HseException(Exception):
    """
    @SUB@ hse.HseException
    """

    def __init__(self, returncode: int) -> None: ...
    @property
    def returncode(self) -> int:
        """
        @SUB@ hse.HseException.returncode
        """
        ...
    @property
    def ctx(self) -> ErrCtx:
        """
        @SUB@ hse.HseException.ctx
        """
        ...

@unique
class KvdbSyncFlag(IntFlag):
    """
    @SUB@ hse.KvdbSyncFlag
    """

    ASYNC = ...

# ifdef HSE_PYTHON_EXPERIMENTAL
@unique
class KvdbCompactFlag(IntFlag):
    """
    @SUB@ hse.KvdbCompactFlag
    """

    CANCEL = ...
    SAMP_LWM = ...

# endif
@unique
class Mclass(Enum):
    """
    @SUB@ hse.Mclass
    """

    CAPACITY = ...
    STAGING = ...
    PMEM = ...

class Kvdb:
    def close(self) -> None:
        """
        @SUB@ hse.Kvdb.close
        """
        ...
    @staticmethod
    def create(kvdb_home: Union[str, os.PathLike[str]], *params: str) -> None:
        """
        @SUB@ hse.Kvdb.create
        """
        ...
    @staticmethod
    def drop(kvdb_home: Union[str, os.PathLike[str]]) -> None:
        """
        @SUB@ hse.Kvdb.drop
        """
        ...
    @staticmethod
    def open(kvdb_home: Union[str, os.PathLike[str]], *params: str) -> Kvdb:
        """
        @SUB@ hse.Kvdb.open
        """
        ...
    @property
    def home(self) -> pathlib.Path:
        """
        @SUB@ hse.Kvdb.home
        """
        ...
    def param(self, param: str) -> str:
        """
        @SUB@ hse.Kvdb.param
        """
        ...
    @property
    def kvs_names(self) -> List[str]:
        """
        @SUB@ hse.Kvdb.kvs_names
        """
        ...
    def kvs_create(self, name: str, *params: str) -> None:
        """
        @SUB@ hse.Kvdb.kvs_create
        """
        ...
    def kvs_drop(self, name: str) -> None:
        """
        @SUB@ hse.Kvdb.kvs_drop
        """
        ...
    def kvs_open(self, name: str, *params: str) -> Kvs:
        """
        @SUB@ hse.Kvdb.kvs_open
        """
        ...
    def sync(self, flags: Optional[KvdbSyncFlag] = ...) -> None:
        """
        @SUB@ hse.Kvdb.sync
        """
        ...
    def mclass_info(self, mclass: Mclass) -> MclassInfo:
        """
        @SUB@ hse.Kvdb.mclass_info
        """
        ...
    def mclass_is_configured(self, mclass: Mclass) -> bool:
        """
        @SUB@ hse.Kvdb.mclass_is_configured
        """
        ...
    # ifdef HSE_PYTHON_EXPERIMENTAL
    def compact(self, flags: Optional[KvdbCompactFlag] = ...) -> None:
        """
        @SUB@ hse.Kvdb.compact
        """
        ...
    @property
    def compact_status(self) -> KvdbCompactStatus:
        """
        @SUB@ hse.Kvdb.compact_status
        """
        ...
    # endif
    @staticmethod
    def storage_add(kvdb_home: Union[str, os.PathLike[str]], params: str) -> None:
        """
        @SUB@ hse.Kvdb.storage_add
        """
    def transaction(self) -> KvdbTransaction:
        """
        @SUB@ hse.Kvdb.transaction
        """
        ...

class KvsPutFlag(IntFlag):
    """
    @SUB@ hse.KvsPutFlag
    """

    PRIO = ...
    VCOMP_OFF = ...

class CursorCreateFlag(IntFlag):
    """
    @SUB@ hse.CursorCreateFlag
    """

    REV = ...

# ifdef HSE_PYTHON_EXPERIMENTAL
class KvsPfxProbeCnt(Enum):
    """
    @SUB@ hse.KvsPfxProbeCnt
    """

    ZERO = ...
    ONE = ...
    MUL = ...

# endif

class Kvs:
    @property
    def name(self) -> str:
        """
        @SUB@ hse.Kvs.name
        """
        ...
    def param(self, param: str) -> str:
        """
        @SUB@ hse.Kvs.param
        """
        ...
    def close(self) -> None:
        """
        @SUB@ hse.Kvs.close
        """
        ...
    def put(
        self,
        key: Union[str, bytes, SupportsBytes],
        value: Optional[Union[str, bytes, SupportsBytes]],
        txn: Optional[KvdbTransaction] = ...,
        flags: Optional[KvsPutFlag] = ...,
    ) -> None:
        """
        @SUB@ hse.Kvs.put
        """
        ...
    def get(
        self,
        key: Union[str, bytes, SupportsBytes],
        txn: Optional[KvdbTransaction] = ...,
        buf: Optional[bytearray] = ...,
    ) -> Tuple[Optional[bytes], int]:
        """
        @SUB@ hse.Kvs.get
        """
        ...
    def delete(
        self,
        key: Union[str, bytes, SupportsBytes],
        txn: Optional[KvdbTransaction] = ...,
    ) -> None:
        """
        @SUB@ hse.Kvs.delete
        """
        ...
    def prefix_delete(
        self, pfx: Union[str, bytes], txn: Optional[KvdbTransaction] = ...
    ) -> None:
        """
        @SUB@ hse.Kvs.prefix_delete
        """
        ...
    # ifdef HSE_PYTHON_EXPERIMENTAL
    def prefix_probe(
        self,
        pfx: Union[str, bytes],
        key_buf: bytearray = ...,
        value_buf: Optional[bytearray] = ...,
        txn: Optional[KvdbTransaction] = ...,
    ) -> Tuple[KvsPfxProbeCnt, Optional[bytes], int, Optional[bytes], int]:
        """
        @SUB@ hse.Kvs.prefix_probe
        """
        ...
    # endif
    def cursor(
        self,
        filt: Optional[Union[str, bytes]] = ...,
        txn: Optional[KvdbTransaction] = ...,
        flags: Optional[CursorCreateFlag] = ...,
    ) -> KvsCursor:
        """
        @SUB@ hse.Kvs.cursor
        """
        ...

class KvdbTransactionState(Enum):
    """
    @SUB@ hse.KvdbTransactionState
    """

    INVALID: int
    ACTIVE: int
    COMMITTED: int
    ABORTED: int

class KvdbTransaction:
    """
    @SUB@ hse.KvdbTransaction
    """

    def __enter__(self) -> KvdbTransaction: ...
    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> None: ...
    def begin(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.begin
        """
        ...
    def commit(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.commit
        """
        ...
    def abort(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.abort
        """
        ...
    @property
    def state(self) -> KvdbTransactionState:
        """
        @SUB@ hse.KvdbTransaction.state
        """
        ...

class KvsCursor:
    def __enter__(self) -> KvsCursor: ...
    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> None: ...
    @property
    def eof(self) -> bool:
        """
        @SUB@ hse.KvsCursor.eof
        """
        ...
    def destroy(self) -> None:
        """
        @SUB@ hse.KvsCursor.destroy
        """
        ...
    def items(
        self,
        key_buf: Optional[bytearray] = ...,
        value_buf: Optional[bytearray] = ...,
    ) -> Iterator[Tuple[Optional[bytes], Optional[bytes]]]:
        """
        @SUB@ hse.KvsCursor.items
        """
        ...
    def read(
        self, key_buf: Optional[bytearray] = ..., value_buf: Optional[bytearray] = ...
    ) -> Tuple[Optional[bytes], Optional[bytes]]:
        """
        @SUB@ hse.KvsCursor.read
        """
        ...
    def update_view(
        self,
        txn: Optional[KvdbTransaction] = ...,
    ) -> None:
        """
        @SUB@ hse.KvsCursor.update_view
        """
        ...
    def seek(self, key: Optional[Union[str, bytes, SupportsBytes]]) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek
        """
        ...
    def seek_range(
        self,
        filt_min: Optional[Union[str, bytes, SupportsBytes]],
        filt_max: Optional[Union[str, bytes, SupportsBytes]],
    ) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek_range
        """
        ...

# ifdef HSE_PYTHON_EXPERIMENTAL
class KvdbCompactStatus:
    """
    @SUB@ hse.KvdbCompactStatus
    """

    @property
    def samp_lwm(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_lwm
        """
        ...
    @property
    def samp_hwm(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_hwm
        """
        ...
    @property
    def samp_curr(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_curr
        """
        ...
    @property
    def active(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.active
        """
        ...
    @property
    def canceled(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.canceled
        """
        ...

# endif

class MclassInfo:
    """
    @SUB@ hse.MclassInfo
    """

    @property
    def allocated_bytes(self) -> int:
        """
        @SUB@ hse.MclassInfo.allocated_bytes
        """
        ...
    @property
    def used_bytes(self) -> int:
        """
        @SUB@ hse.MclassInfo.used_bytes
        """
        ...
    @property
    def path(self) -> pathlib.Path:
        """
        @SUB@ hse.MclassInfo.path
        """
