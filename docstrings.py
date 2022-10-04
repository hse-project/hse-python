#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

# This script exists because Python/Cython tooling is absolutely horrible. In
# what world do 2 copies of the same docstring have to be kept in a pyx file
# and a pyi file for there to be support for __doc__ and language servers, et.
# al.
#
# PYTHON IS PAIN...

import argparse
import pathlib
import re
import sys
from io import StringIO
from typing import List

__DOCSTRINGS = {
    "hse.init": """
Initialize the HSE subsystem.

This function initializes a range of different internal HSE structures. It
must be called before any other HSE functions are used.

This function is not thread safe and is idempotent.

Args:
    config: Path to a global configuration file.
    params: Parameters in key=value format.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.fini": """
Shutdown the HSE subsystem.

This function cleanly finalizes a range of different internal HSE structures.
It should be called prior to application exit.

After invoking this function, calling any other HSE functions will
result in undefined behavior unless HSE is re-initialized.

This function is not thread safe.
""",

    "hse.param": """
Get HSE global parameter.

Puts the stringified bersion of the parameter value into the buffer.

This function is thread safe.

Args:
    param: Parameter name.

Returns:
    str: Stringified version of the parameter value.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.ErrCtx": """
Error context. Wrapper around ``hse_err_ctx``.
""",

    "hse.HseException": """
Raised when HSE encounters an error. Wrapper around ``hse_err_t``.
""",

    "hse.HseException.returncode": """
Errno value returned by HSE.
""",

    "hse.HseException.ctx": """
Error context.
""",

    "hse.Kvdb.close": """
Close a KVDB.

After invoking this function, calling any other KVDB functions will
result in undefined behavior unless the KVDB is re-opened.

This function is not thread safe.

Args:
    kvdb: KVDB handle from ``Kvdb.open()``.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.compact": """
Request a data compaction operation.

In managing the data within an HSE KVDB, there are maintenance activities
that occur as background processing. The application may be aware that it is
advantageous to do enough maintenance now for the database to be as compact
as it ever would be in normal operation.

See the property ``Kvdb.compact_status``.

This function is thread safe.

Args:
    flags: Compaction flags.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.compact_status": """
Get status of an ongoing compaction activity.

The caller can examine the fields of the ``KvdbCompactStatus`` class to
determine the current state of maintenance compaction.

This property is thread safe.

Returns:
    KvdbCompactStatus: Status of compaction request.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.create": """
Create a KVDB.

This function is not thread safe.

Args:
    kvdb_home: KVDB home directory.
    params: List of parameters in key=value format.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.drop": """
Drop a KVDB.

It is an error to call this function on a KVDB that is open.

This function is not thread safe.

Args:
    kvdb_home: KVDB home directory

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.home": """
Get the KVDB home.

This function is thread safe.

Returns:
    pathlib.Path: KVDB home.
""",

    "hse.Kvdb.kvs_names": """
Get the names of the KVSs within the given KVDB.

Key-value stores (KVSs) are opened by name. This function allocates a vector
of allocated strings.

This function is thread safe.

Returns:
    List[str]: List of KVS names.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.mclass_info": """
Get media class information from a KVDB.

This function is thread safe.

Args:
    mclass: Media class to query for.

Returns:
    MclassInfo: Media class information.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.mclass_is_configured": """
Check if a media class is configured for a KVDB.

This function is thread safe.

Returns:
    bool: Whether or not mclass is configured.
""",

    "hse.Kvdb.open": """
Open a KVDB.

This function is not thread safe.

Args:
    kvdb_home: KVDB home directory.
    params: List of parameters in key=value format.

Returns:
    Kvdb: A KVDB handle.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.param": """
Get KVDB parameter.

Puts the stringified bersion of the parameter value into the buffer.

This function is thread safe.

Args:
    param: Parameter name.

Returns:
    str: Stringified version of the parameter value.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.storage_add": """
Add a new media class storage to an existing offline KVDB.

This function is not thread safe.

Args:
    kvdb_home: KVDB home directory.
    params: List of parameters in key=value format.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvdbSyncFlag": """
Attributes:
    ASYNC: Return immediately after initiating operation
""",

    "hse.Kvdb.sync": """
Sync data in all of the referenced KVDB's KVSs to stable media.

Args:
    flags: Flags for operation specialization.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvs.close": """
Close an open KVS.

After invoking this function, calling any other KVS functions will
result in undefined behavior unless the KVS is re-opened.

This function is not thread safe.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.kvs_create": """
Create a new KVS within the referenced KVDB.

This function is not thread safe.

Args:
    name: KVS name.
    params: List of parameters in key=value format.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.kvs_drop": """
Drop a KVS from the referenced KVDB.

It is an error to call this function on a KVS that is open.

This function is not thread safe.

Args:
    name: KVS name.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvdb.kvs_open": """
Open a KVS in a KVDB.

This function is not thread safe.

Args:
    name: KVS name.
    params: List of parameters in key=value format.

Returns:
    Kvs: A KVS handle.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvs.delete": """
Delete the key and its associated value from the KVS.

It is not an error if the key does not exist within the KVS. See
``KvdbTransaction`` for information on how deletes within transactions are
handled.

Args:
    key: Key to be deleted from the KVS.
    txn: Transaction context.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvs.get": """
Retrieve the value for a given key from the KVS.

If the key exists in the KVS, then the returned key is not None.
If the caller's value buffer is large enough then the data will be returned.
Regardless, the actual length of the value is returned. See
``KvdbTransaction`` for information on how gets within transactions are handled.

This function is thread safe.

Args:
    key: Key to get from the KVS.
    txn: Transaction context.
    buf: Buffer into which the value associated with ``key`` will be copied.

Returns:
    tuple: Value and length of the value.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvs.name": """
Get KVS parameter.

Puts the stringified bersion of the parameter value into the buffer.

This function is thread safe.

Args:
    param: Parameter name.

Returns:
    str: Stringified version of the parameter value.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvs.prefix_delete": """
Delete all key-value pairs matching the key prefix from a KVS storing
segmented keys.

This interface is used to delete an entire range of segmented keys. To do
this the caller passes a filter with a length equal to the KVS's key prefix
length. It is not an error if no keys exist matching the filter. If there is
a filtered iteration in progress, then that iteration can fail if
``Kvs.prefix_delete()`` is called with a filter matching the iteration.

If ``Kvs.prefix_delete()`` is called from a transaction context, it affects
no key-value mutations that are part of the same transaction. Stated
differently, for KVS commands issued within a transaction, all calls to
``Kvs.prefix_delete()`` are treated as though they were issued serially at
the beginning of the transaction regardless of the actual order these
commands appeared in.

Args:
    pfx: Prefix of keys to delete.
    txn: Transaction context.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.Kvs.prefix_probe": """
Probe for a prefix.

Given a prefix, outputs how many matches were encountered - zero, one or
multiple.

Args:
    pfx: Prefix to be probed.
    key_buf: Buffer which will be populated with contents of first seen key.
    val_buf: Buffer which will be populated with value for ``key_buf``
    txn: Transaction context.

Returns:
    tuple: Tuple of ``KvsPfxProbeCnt``, key, length of key, value, and length of
        value.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvsPutFlags": """
Attributes:
    PRIO: Operation will not be throttled.
    VCOMP_OFF: Value will not be compressed.
    VCOMP_ON: Value may be compressed.
""",

    "hse.Kvs.put": """
Put a key-value pair into KVS.

If the key already exists in the KVS then the value is effectively
overwritten. See ``KvdbTransaction`` for information on how puts within
transactions are handled.

The HSE KVDB attempts to maintain reasonable QoS and for high-throughput
clients this results in very short sleep's being inserted into the put path.
For some kinds of data (e.g., control metadata) the client may wish to not
experience that delay. For relatively low data rate uses, the caller can set
the ``KvsPutFlags.PRIO`` flag for an ``Kvs.put()``. Care should be taken when
doing so to ensure that the system does not become overrun. As a rough
approximation, doing 1M priority puts per second marked as PRIO is likely an
issue. On the other hand, doing 1K small puts per second marked as PRIO is
almost certainly fine.

If compression is on by default for the given kvs, then ``Kvs.put()`` will
attempt to compress the value unless the ``KvsPutFlags.VCOMP_OFF`` flag is
given. Otherwise, the ``KvsPutFlags.VCOMP_OFF`` flag is ignored.

If compression is off by default for the given kvs, then ``Kvs.put()`` will not
attempt to compress a value unless the ``KvsPutFlags.VCOMP_ON`` flag is given.
Otherwise, the ``KvsPutFlags.VCOMP_ON`` flag is ignored.

This function is thread safe.

Args:
    key: Key to put into KVS.
    value: Value associated with ``key``.
    txn: Transaction context.
    flags: Flags for operation specialization.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvdbTransactionState": """
Transaction state.
""",

    "hse.KvdbTransaction": """
The HSE KVDB provides transactions with operations spanning KVSs within a
single KVDB. These transactions have snapshot isolation (a specific form of
MVCC) with the normal semantics (see "Concurrency Control and Recovery in
Database Systems" by PA Bernstein).

One unusual aspect of the API as it relates to transactions is that the data
object that is used to hold client-level transaction state is allocated
separately from the transaction being initiated. As a result, the same object
handle should be reused again and again.

In addition, there is very limited coupling between threading and
transactions. A single thread may have many transactions in flight
simultaneously. Also operations within a transaction can be performed by
multiple threads. The latter mode of operation must currently restrict calls
so that only one thread is actively performing an operation in the context of
a particular transaction at any particular time.

The general lifecycle of a transaction is as follows:

                      +----------+
                      | INVALID  |
                      +----------+
                            |
                            v
                      +----------+
    +---------------->|  ACTIVE  |<----------------+
    |                 +----------+                 |
    |  +-----------+    |      |     +----------+  |
    +--| COMMITTED |<---+      +---->| ABORTED  |--+
       +-----------+                 +----------+

When a transaction is initially allocated, it starts in the INVALID state.
When ``KvdbTransaction.begin()`` is called with transaction in the INVALID,
COMMITTED, or ABORTED states, it moves to the ACTIVE state. It is an error to
call the hse_kvdb_txn_begin() function on a transaction in the ACTIVE state.
For a transaction in the ACTIVE state, only the functions
``KvdbTransaction.commit()`` or``KvdbTransaction.abort()`` may be
called.

When a transaction becomes ACTIVE, it establishes an ephemeral snapshot view
of the state of the KVDB. Any data mutations outside of the transaction's
context after that point are not visible to the transaction. Similarly, any
mutations performed within the context of the transaction are not visible
outside of the transaction unless and until it is committed. All such
mutations become visible atomically when the transaction commits.

Within a transaction whenever a write operation e.g., put, delete, etc.,
encounters a write conflict, that operation returns an error code of
ECANCELED. The caller is then expected to re-try the operation in a new
transaction, see ``HseException``.
""",

    "hse.Kvdb.transaction": """
Allocate transaction object.

This object can and should be re-used many times to avoid the overhead of
allocation.

This function is thread safe.

Returns:
    KvdbTransaction: A transaction handle.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvdbTransaction.abort": """
Abort/rollback transaction.

The call fails if the referenced transaction is not in the ACTIVE state.

This function is thread safe with different transactions.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvdbTransaction.begin": """
Initiate transaction.

The call fails if the transaction handle refers to an ACTIVE transaction.

This function is thread safe with different transactions.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvdbTransaction.commit": """
Commit all the mutations of the referenced transaction.

The call fails if the referenced transaction is not in the ACTIVE state.

This function is thread safe with different transactions.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvdbTransaction.state": """
Retrieve the state of the referenced transaction.

This function is thread safe with different transactions.

Returns:
    KvdbTransactionState: Transaction's state.
""",

    "hse.CursorCreateFlag": """
Attributes:
    REV: iterate in reverse lexicographical order
""",

    "hse.Kvs.cursor": """
Non-transactional cursors:

If ``txn`` is None, a non-transactional cursor is created. Non-transactional
cursors have an ephemeral snapshot view of the KVS at the time it the cursor
is created. The snapshot view is maintained for the life of the cursor.
Writes to the KVS (put, deletes, etc.) made after the cursor is created will
not be visible to the cursor unless ``KvsCursor.update_view()`` is used to
obtain a more recent snapshot view. Non-transactional cursors can be used on
transactional and non-transactional KVSs.

Transactional cursors:

If ``txn`` is not None, it must be a valid transaction handle or undefined
behavior will result. If it is a valid handle to a transaction in the ACTIVE
state, a transactional cursor is created. A transaction cursor's view
includes the transaction's writes overlaid on the transaction's ephemeral
snapshot view of the KVS. If the transaction is committed or aborted before
the cursor is destroyed, the cursor's view reverts to same snaphsot view the
transaction had when first became active. The cursor will no longer be able
to see the transaction's writes. Calling ``KvsCursor.update_view()`` on a
transactional cursor is a no-op and has no effect on the cursor's view.
Transactional cursors can only be used on transactional KVSs.

Prefix vs non-prefix cursors:

Parameter ``filter`` can be used to iterate over the subset
of keys in the KVS whose first ``len(filter)`` bytes match the first
``len(filter)`` bytes pointed to by ``filter``.

A prefix cursor is created when:
    * KVS was created with ``prefix.length`` > 0 (i.e., it is a prefix KVS), and
    * ``filter`` != None and ``len(filter)`` >= ``prefix.length``.

Otherwise, a non-prefix cursor is created.

Applications should arrange their key-value data to avoid the need for
non-prefix cursors as they are significantly slower and more
resource-intensive than prefix cursors. Note that simply using a filter
doesn't create a prefix cursor -- it must meet the two conditions listed
above.

This function is thread safe across disparate cursors.

Args:
    filt: Iteration limited to keys matching this prefix filter.
    txn: Transaction context.
    flags: Flags for operation specialization.

Returns:
    KvsCursor: A cursor handle.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvsCursor.destroy": """
Destroy cursor.

After invoking this function, calling any other cursor functions
with this handle will result in undefined behavior.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvsCursor.items": """
Convenience function to return an iterator over key-value pairs in a cursor's
view.

Args:
    key_buf: Buffer into which keys will be copied.
    value_buf: Buffer into which values will be copied.

Returns:
    Iterator of key-value pairs.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvsCursor.read": """
Iteratively access the elements pointed to by the cursor.

Read a key-value pair from the cursor, advancing the cursor past its current
location.

If the cursor is at EOF, attempts to read from it will not change the
state of the cursor.

This function is thread safe across disparate cursors.

Args:
    key_buf: Buffer into which the next key will be copied.
    value_buf: Buffer into which the next value will be copied.

Returns:
    tuple: Key-value pair.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvsCursor.seek": """
Move the cursor to point at the key-value pair at or closest to ``key``.

The next ``KvsCursor.read()`` will start at this point.

This function is thread safe across disparate cursors.

Args:
    key: Key to find.

Returns:
    bytes: Next key in sequence.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvsCursor.seek_range": """
Move the cursor to the closest match to key, gated by the given filter.

Keys read from this cursor will belong to the closed interval defined by the
given filter: [``filt_min``, ``filt_max``]. For KVSs storing segmented keys,
performance will be enhanced when ``len(filt_min)`` and ``len(filt_max)`` are
greater than or equal to the KVS key prefix length.

This is only supported for forward cursors.

This function is thread safe across disparate cursors.

Args:
    filt_min: Filter minimum.
    filt_max: Filter maximum.

Returns:
    bytes: Next key in sequence.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "hse.KvsCursor.update_view": """
Update a the cursor view.

This operation updates the snapshot view of a non-transaction cursor. It is a
no-op on transaction cursors.

This function is thread safe across disparate cursors.

Args:
    flags: Flags for operation specialization.

Raises:
    HseException: Underlying C function returned a non-zero value.
""",

    "limits.KVS_COUNT_MAX": """
Maximum number of KVSs contained within one KVDB.
""",

    "limits.KVS_KEY_LEN_MAX": """
Maximum key length.

A common requirement clients have for key length is 1024.
Combined with a discriminant and (potentially) a chunk key, this pushes us to
1030 bytes keys. Looking at the packing for the on-media format for data, we
can have at most 3 keys of such large size in a 4k page. Lopping off 64-bytes
for other data, and we can have 3 keys of 1344 bytes.
""",

    "limits.KVS_NAME_LEN_MAX": """
Maximum length of a KVS name.

KVS names are NULL-terminated strings. The string plus the NULL-terminator
must fit into a ``KVS_NAME_LEN_MAX`` byte buffer.
""",

    "limits.KVS_VALUE_LEN_MAX": """
Max value length is 1MiB.
""",

    "limits.KVS_PFX_LEN_MAX": """
Max key prefix length.
""",

    "hse.KvdbCompactStatus": """
Status of a compaction request.
""",

    "hse.KvdbCompactStatus.samp_lwm": """
space amp low water mark (%).
""",

    "hse.KvdbCompactStatus.samp_hwm": """
space amp high water mark (%).
""",

    "hse.KvdbCompactStatus.samp_curr": """
current space amp (%).
""",

    "hse.KvdbCompactStatus.active": """
is an externally requested compaction underway.
""",

    "hse.KvdbCompactStatus.canceled": """
was an externally requested compaction canceled.
""",

    "hse.Mclass": """
Media class types.

Attributes:
    CAPACITY: Capacity media class.
    STAGING: Staging media class.
    PMEM: PMEM media class.
""",

    "hse.MclassInfo": """
Media class information.
""",

    "hse.MclassInfo.allocated_bytes": """
Allocated storage space for a media class.
""",

    "hse.MclassInfo.used_bytes": """
Used storage space for a media class.
""",

    "hse.MclassInfo.path": """
Path to the media class.
""",

    "hse.KvsPfxProbeCnt": """
Number of keys found from a prefix probe operation.

Attributes:
    ZERO: Zero keys found with prefix.
    ONE: One key found with prefix.
    MUL: Multiple keys found with prefix.
""",

    "hse.version.STRING": """
A string representing the HSE libary version.
""",

    "hse.version.MAJOR": """
Major version of HSE.
""",

    "hse.version.MINOR": """
Minor version of HSE.
""",

    "hse.version.PATCH": """
Patch version of HSE.
""",

    "hse.KvdbCompactFlag": """
Kvdb.compact() flags.
"""
}


__DOCSTRING_PATTERN = re.compile(r"(\s*)@SUB@\s+([a-zA-Z0-9._]+)")
__INDENT = " " * 4  # 4 space indents in source files


def insert(input_file: pathlib.Path, output_file: pathlib.Path) -> None:
    """
    Insert docstrings into a file out of place. `file.py.in` will output to
    `file.py`. If the input file has an older modified time than the previously
    created output file, then `insert` is a no-op. If the `docstrings.toml` has
    a newer modified time than the output file, the docstring insertion will
    always occur.

    Example location of where text replacement would happen::

        # module.py
        class MyClass:
            '''
            @SUB@ module.MyClass.__doc__ # <- text replacement
            '''

            def func(self):
                '''
                @SUB@ module.MyClass.__doc__ # <- text replacement
                '''

    Args:
        input_file: Path to file containing templated docstrings.
        output_file: Path to output file.
    """
    with open(input_file, "r", encoding="utf-8") as inf:
        output_lines: List[str] = []
        for line in inf.readlines():
            match = __DOCSTRING_PATTERN.search(line)
            if match is None:
                output_lines.append(line)
                continue
            indents = int(len(match.group(1)) / 4)
            key = match.group(2)
            if key in __DOCSTRINGS.keys():  # pylint: disable=consider-iterating-dictionary
                with StringIO(__DOCSTRINGS[key].lstrip()) as docstring:
                    output_lines.extend(
                        map(
                            # pylint: disable-next=cell-var-from-loop
                            lambda s: __INDENT * indents + s if not s.isspace() else s,
                            docstring.readlines(),
                        )
                    )

        with open(output_file, "w", encoding="utf-8") as outf:
            for line in output_lines:
                outf.write(line)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Insert docstrings into input files")
    parser.add_argument("-o", "--output", nargs=1, required=True, help="Output file")
    parser.add_argument(
        "-f", "--file", nargs=1, required=True, type=pathlib.Path, help="Files to manipulate"
    )
    ns = parser.parse_args(sys.argv[1:])

    output = ns.output[0]
    file = ns.file[0]

    insert(file, output)
