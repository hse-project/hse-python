# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import os
import pathlib
from enum import Enum, IntFlag, unique
from types import TracebackType
from typing import Iterator, List, Optional, SupportsBytes, Tuple, Type, Any, Union

def init(config: Optional[Union[str, os.PathLike[str]]] = ..., *params: str) -> None:
    """
    @SUB@ hse.init.__doc__
    """
    ...

def fini() -> None:
    """
    @SUB@ hse.fini.__doc__
    """
    ...

def param(param: str) -> str:
    """
    @SUB@ hse.param.__doc__
    """
    ...

class HseException(Exception):
    """
    @SUB@ hse.HseException.__doc__
    """

    returncode: int
    def __init__(self, returncode: int) -> None: ...

@unique
class KvdbSyncFlag(IntFlag):
    """
    @SUB@ hse.KvdbSyncFlag.__doc__
    """

    ASYNC = ...

# ifdef HSE_PYTHON_EXPERIMENTAL
@unique
class KvdbCompactFlag(IntFlag):
    """
    @SUB@ hse.KvdbCompactFlag.__doc__
    """

    CANCEL = ...
    SAMP_LWM = ...

# endif
@unique
class Mclass(Enum):
    """
    @SUB@ hse.Mclass.__doc__
    """

    CAPACITY = ...
    STAGING = ...
    PMEM = ...

class Kvdb:
    def close(self) -> None:
        """
        @SUB@ hse.Kvdb.close.__doc__
        """
        ...
    @staticmethod
    def create(kvdb_home: Union[str, os.PathLike[str]], *params: str) -> None:
        """
        @SUB@ hse.Kvdb.create.__doc__
        """
        ...
    @staticmethod
    def drop(kvdb_home: Union[str, os.PathLike[str]]) -> None:
        """
        @SUB@ hse.Kvdb.drop.__doc__
        """
        ...
    @staticmethod
    def open(kvdb_home: Union[str, os.PathLike[str]], *params: str) -> Kvdb:
        """
        @SUB@ hse.Kvdb.open.__doc__
        """
        ...
    @property
    def home(self) -> pathlib.Path:
        """
        @SUB@ hse.Kvdb.home.__doc__
        """
        ...
    def param(self, param: str) -> str:
        """
        @SUB@ hse.Kvdb.param.__doc__
        """
        ...
    @property
    def kvs_names(self) -> List[str]:
        """
        @SUB@ hse.Kvdb.kvs_names.__doc__
        """
        ...
    def kvs_create(self, name: str, *params: str) -> None:
        """
        @SUB@ hse.Kvdb.kvs_create.__doc__
        """
        ...
    def kvs_drop(self, name: str) -> None:
        """
        @SUB@ hse.Kvdb.kvs_drop.__doc__
        """
        ...
    def kvs_open(self, name: str, *params: str) -> Kvs:
        """
        @SUB@ hse.Kvdb.kvs_open.__doc__
        """
        ...
    def sync(self, flags: Optional[KvdbSyncFlag] = ...) -> None:
        """
        @SUB@ hse.Kvdb.sync.__doc__
        """
        ...
    def mclass_info(self, mclass: Mclass) -> MclassInfo:
        """
        @SUB@ hse.Kvdb.mclass_info.__doc__
        """
        ...
    # ifdef HSE_PYTHON_EXPERIMENTAL
    def compact(self, flags: Optional[KvdbCompactFlag] = ...) -> None:
        """
        @SUB@ hse.Kvdb.compact.__doc__
        """
        ...
    @property
    def compact_status(self) -> KvdbCompactStatus:
        """
        @SUB@ hse.Kvdb.compact_status.__doc__
        """
        ...
    # endif
    @staticmethod
    def storage_add(kvdb_home: Union[str, "os.PathLike[str]"], params: str) -> None:
        """
        @SUB@ hse.Kvdb.storage_add.__doc__
        """
    def transaction(self) -> KvdbTransaction:
        """
        @SUB@ hse.Kvdb.transaction.__doc__
        """
        ...

class KvsPutFlag(IntFlag):
    """
    @SUB@ hse.KvsPutFlag.__doc__
    """

    PRIO = ...
    VCOMP_OFF = ...

class CursorCreateFlag(IntFlag):
    """
    @SUB@ hse.CursorCreateFlag.__doc__
    """

    REV = ...

# ifdef HSE_PYTHON_EXPERIMENTAL
class KvsPfxProbeCnt(Enum):
    """
    @SUB@ hse.KvsPfxProbeCnt.__doc__
    """

    ZERO = ...
    ONE = ...
    MUL = ...

# endif

class Kvs:
    @property
    def name(self) -> str:
        """
        @SUB@ hse.Kvs.name.__doc__
        """
        ...
    def param(self, param: str) -> str:
        """
        @SUB@ hse.Kvs.param.__doc__
        """
        ...
    def close(self) -> None:
        """
        @SUB@ hse.Kvs.close.__doc__
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
        @SUB@ hse.Kvs.put.__doc__
        """
        ...
    def get(
        self,
        key: Union[str, bytes, SupportsBytes],
        txn: Optional[KvdbTransaction] = ...,
        buf: Optional[bytearray] = ...,
    ) -> Tuple[Optional[bytes], int]:
        """
        @SUB@ hse.Kvs.get.__doc__
        """
        ...
    def delete(
        self,
        key: Union[str, bytes, SupportsBytes],
        txn: Optional[KvdbTransaction] = ...,
    ) -> None:
        """
        @SUB@ hse.Kvs.delete.__doc__
        """
        ...
    def prefix_delete(
        self, pfx: Union[str, bytes], txn: Optional[KvdbTransaction] = ...
    ) -> None:
        """
        @SUB@ hse.Kvs.prefix_delete.__doc__
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
        @SUB@ hse.Kvs.prefix_probe.__doc__
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
        @SUB@ hse.Kvs.cursor.__doc__
        """
        ...

class KvdbTransactionState(Enum):
    """
    @SUB@ hse.KvdbTransactionState.__doc__
    """

    INVALID: int
    ACTIVE: int
    COMMITTED: int
    ABORTED: int

class KvdbTransaction:
    """
    @SUB@ hse.KvdbTransaction.__doc__
    """

    def __enter__(self) -> KvdbTransaction: ...
    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[Any],
        exc_tb: Optional[TracebackType],
    ) -> None: ...
    def begin(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.begin.__doc__
        """
        ...
    def commit(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.commit.__doc__
        """
        ...
    def abort(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.abort.__doc__
        """
        ...
    @property
    def state(self) -> KvdbTransactionState:
        """
        @SUB@ hse.KvdbTransaction.state.__doc__
        """
        ...

class KvsCursor:
    def __enter__(self) -> KvsCursor: ...
    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[Any],
        exc_tb: Optional[TracebackType],
    ) -> None: ...
    @property
    def eof(self) -> bool:
        """
        @SUB@ hse.KvsCursor.eof.__doc__
        """
        ...
    def destroy(self) -> None:
        """
        @SUB@ hse.KvsCursor.destroy.__doc__
        """
        ...
    def items(self) -> Iterator[Tuple[bytes, Optional[bytes]]]:
        """
        @SUB@ hse.KvsCursor.items.__doc__
        """
        ...
    def read(self) -> Tuple[Optional[bytes], Optional[bytes]]:
        """
        @SUB@ hse.KvsCursor.read.__doc__
        """
        ...
    def update_view(
        self,
        txn: Optional[KvdbTransaction] = ...,
    ) -> None:
        """
        @SUB@ hse.KvsCursor.update_view.__doc__
        """
        ...
    def seek(self, key: Optional[Union[str, bytes, SupportsBytes]]) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek.__doc__
        """
        ...
    def seek_range(
        self,
        filt_min: Optional[Union[str, bytes, SupportsBytes]],
        filt_max: Optional[Union[str, bytes, SupportsBytes]],
    ) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek_range.__doc__
        """
        ...

# ifdef HSE_PYTHON_EXPERIMENTAL
class KvdbCompactStatus:
    """
    @SUB@ hse.KvdbCompactStatus.__doc__
    """

    @property
    def samp_lwm(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_lwm.__doc__
        """
        ...
    @property
    def samp_hwm(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_hwm.__doc__
        """
        ...
    @property
    def samp_curr(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_curr.__doc__
        """
        ...
    @property
    def active(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.active.__doc__
        """
        ...
    @property
    def canceled(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.canceled.__doc__
        """
        ...

# endif

class MclassInfo:
    """
    @SUB@ hse.MclassInfo.__doc__
    """

    @property
    def allocated_bytes(self) -> int:
        """
        @SUB@ hse.MclassInfo.allocated_bytes.__doc__
        """
        ...
    @property
    def used_bytes(self) -> int:
        """
        @SUB@ hse.MclassInfo.used_bytes.__doc__
        """
        ...
    @property
    def path(self) -> pathlib.Path:
        """
        @SUB@ hse.MclassInfo.path.__doc__
        """
