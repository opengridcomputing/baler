from __future__ import print_function
import cython
from cpython cimport PyObject, Py_INCREF
import datetime as dt
import numpy as np
cimport numpy as np
from libc.stdint cimport *
from libc.stdlib cimport *
from sosdb import Array
cimport Bs

cpdef uint64_t btkn_type_mask_from_str(const char *_str):
    return Bs.btkn_type_mask_from_str(_str)

cdef class Bstore:

    cdef Bs.bstore_t c_store
    cdef iters
    cdef plugin
    cdef path

    def __cinit__(self, plugin='bstore_sos'):
        self.c_store = NULL
        self.plugin = plugin
        self.iters = []

    def open(self, path, int flags=Bs.O_RDWR, int mode=0660):
        self.path = path
        self.c_store = Bs.bstore_open(self.plugin, self.path, flags, mode)
        if self.c_store is NULL:
            raise ValueError()
        return self

    def close(self):
        if self.c_store is not NULL:
            Bs.bstore_close(self.c_store)
            self.c_store = NULL

    def __dealloc__(self):
        # automatically close at deallocation, just in case that the application
        # has not already closed the store.
        self.close()

    cpdef tkn_by_id(self, tkn_id):
        cdef Bs.btkn_id_t id_ = <Bs.btkn_id_t>tkn_id
        cdef Bs.btkn_t btkn
        cdef Btkn tkn
        btkn = Bs.bstore_tkn_find_by_id(self.c_store, id_)
        if btkn != NULL:
            tkn = Btkn()
            tkn.c_tkn = btkn
            return tkn
        raise NameError("{0} is not a valid Token Id".format(id_))

    cpdef tkn_by_name(self, tkn_name):
        cdef Bs.btkn_t btkn
        cdef Btkn tkn
        btkn = Bs.bstore_tkn_find_by_name(self.c_store, tkn_name, len(tkn_name))
        if btkn != NULL:
            tkn = Btkn()
            tkn.c_tkn = btkn
            return tkn
        return None

    cpdef ptn_by_id(self, ptn_id):
        cdef Bs.bptn_id_t id_ = <Bs.bptn_id_t>ptn_id
        cdef Bs.bptn_t c_ptn
        cdef Bptn ptn
        c_ptn = Bs.bstore_ptn_find(self.c_store, id_)
        if c_ptn != NULL:
            ptn = Bptn()
            ptn.c_ptn = c_ptn
            ptn.store = self
            return ptn
        return None

BTKN_TYPE_TYPE = Bs.BTKN_TYPE_TYPE
BTKN_TYPE_PRIORITY = Bs.BTKN_TYPE_PRIORITY
BTKN_TYPE_VERSION = Bs.BTKN_TYPE_VERSION
BTKN_TYPE_TIMESTAMP = Bs.BTKN_TYPE_TIMESTAMP
BTKN_TYPE_HOSTNAME = Bs.BTKN_TYPE_HOSTNAME
BTKN_TYPE_SERVICE = Bs.BTKN_TYPE_SERVICE
BTKN_TYPE_PID = Bs.BTKN_TYPE_PID
BTKN_TYPE_IP4_ADDR = Bs.BTKN_TYPE_IP4_ADDR
BTKN_TYPE_IP6_ADDR = Bs.BTKN_TYPE_IP6_ADDR
BTKN_TYPE_ETH_ADDR = Bs.BTKN_TYPE_ETH_ADDR
BTKN_TYPE_HEX_INT = Bs.BTKN_TYPE_HEX_INT
BTKN_TYPE_DEC_INT = Bs.BTKN_TYPE_DEC_INT
BTKN_TYPE_SEPARATOR = Bs.BTKN_TYPE_SEPARATOR
BTKN_TYPE_FLOAT = Bs.BTKN_TYPE_FLOAT
BTKN_TYPE_PATH = Bs.BTKN_TYPE_PATH
BTKN_TYPE_URL = Bs.BTKN_TYPE_URL
BTKN_TYPE_WORD = Bs.BTKN_TYPE_WORD
BTKN_TYPE_TEXT = Bs.BTKN_TYPE_TEXT
BTKN_TYPE_WHITESPACE = Bs.BTKN_TYPE_WHITESPACE

tkn_type_strs = {
    Bs.BTKN_TYPE_TYPE : "<type>",
    Bs.BTKN_TYPE_PRIORITY : "<prio>",
    Bs.BTKN_TYPE_VERSION : "<vers>",
    Bs.BTKN_TYPE_TIMESTAMP : "<ts>",
    Bs.BTKN_TYPE_HOSTNAME : "<host>",
    Bs.BTKN_TYPE_SERVICE : "<svc>",
    Bs.BTKN_TYPE_PID : "<pid>",
    Bs.BTKN_TYPE_IP4_ADDR : "<ip4>",
    Bs.BTKN_TYPE_IP6_ADDR : "<ip6>",
    Bs.BTKN_TYPE_ETH_ADDR : "<mac>",
    Bs.BTKN_TYPE_HEX_INT : "<hex>",
    Bs.BTKN_TYPE_DEC_INT : "<dec>",
    Bs.BTKN_TYPE_SEPARATOR : "<sep>",
    Bs.BTKN_TYPE_FLOAT : "<float>",
    Bs.BTKN_TYPE_PATH : "<path>",
    Bs.BTKN_TYPE_URL : "<url>",
    Bs.BTKN_TYPE_WORD : "<word>",
    Bs.BTKN_TYPE_TEXT : "*",
    Bs.BTKN_TYPE_WHITESPACE : " "
}

cdef class Btkn:
    cpdef Bs.btkn_t c_tkn
    cdef Bs.btkn_type_t c_typ

    def __cinit__(self):
        self.c_tkn = NULL

    def __dealloc__(self):
        if self.c_tkn is not NULL:
            Bs.btkn_free(self.c_tkn)
            self.c_tkn = NULL

    cpdef tkn_id(self):
        return self.c_tkn.tkn_id

    cpdef tkn_count(self):
        return self.c_tkn.tkn_count

    cpdef tkn_str(self):
        return self.c_tkn.tkn_str.cstr

    cpdef ptn_tkn_str(self):
        if self.c_tkn.tkn_id in tkn_type_strs:
            return tkn_type_strs[self.c_tkn.tkn_id]
        return self.c_tkn.tkn_str.cstr

    cpdef has_type(self, Bs.btkn_type_t tkn_type):
        if Bs.btkn_has_type(self.c_tkn, tkn_type) != 0:
            return True
        return False

    cpdef Bs.btkn_type_mask_t type_mask(self):
        return self.c_tkn.tkn_type_mask

    cpdef Bs.btkn_type_t first_type(self):
        return Bs.btkn_first_type(self.c_tkn)

    cdef Bs.btkn_t alloc(self):
        return Bs.btkn_alloc(self.c_tkn.tkn_id, self.c_tkn.tkn_type_mask,
                             self.c_tkn.tkn_str.cstr, self.c_tkn.tkn_str.blen)

    cdef Bs.btkn_t dup(self):
        return Bs.btkn_dup(self.c_tkn)

    def __iter__(self):
        self.c_typ = Bs.btkn_first_type(self.c_tkn)
        return self

    def __next__(self):
        while self.c_typ < Bs.BTKN_TYPE_LAST:
            if Bs.btkn_has_type(self.c_tkn, self.c_typ) != 0:
                if self.c_typ == Bs.BTKN_TYPE_WHITESPACE:
                    typ = "<space>"
                typ = tkn_type_strs[self.c_typ]
                self.c_typ += 1
                return typ
            self.c_typ += 1
        raise StopIteration

cdef class Biter:

    cdef Bstore store
    cdef Bs.bstore_iter_t c_iter
    cdef object py_obj

    def __init__(self, Bstore store):
        cdef Bs.bstore_iter_t c_it
        self.store = store
        if self.store.c_store == NULL:
            raise ValueError("The specified store is not open")
        c_it = self.iterNew()
        if c_it is NULL:
            raise MemoryError()
        self.c_iter = c_it

    def __dealloc__(self):
        if self.c_iter is not NULL:
            self.iterDel()
            self.c_iter = NULL

    def __iter__(self):
        """ iterate from current object forward. """
        if not self.py_obj:
            self.py_obj = self.first()
        while self.py_obj:
            yield self.py_obj
            self.py_obj = self.next()

    cdef object obj_wrap(self, void *c_obj):
        raise NotImplementedError

    cdef object obj_update(self, void *c_obj):
        if c_obj == NULL:
            self.py_obj = None
        else:
            self.py_obj = self.obj_wrap(c_obj)
        return self.py_obj

    cpdef unsigned long card(self):
        raise NotImplementedError

    def obj(self):
        return self.obj_update(self.iterObj())

    def first(self):
        return self.obj_update(self.iterFirst())

    def next(self):
        return self.obj_update(self.iterNext())

    def prev(self):
        return self.obj_update(self.iterPrev())

    def last(self):
        return self.obj_update(self.iterLast())

    def get_pos(self):
        """Return the current iterator position

        Returns a string that represents the current iterator
        position. This string can be passed to set_pos() in order to
        start an iterator at a previously saved position. This is
        useful for handling pagination for a web back-end.

        The get_pos() function must be called before the call to
        next() in order to return the iterator position associated
        with the object returned by next(). Since the Python:

            for x in y:
                # ...

        paradigm calls next() implicitly, calling get_pos() inside the
        for loop will return the _next_ position on the iterator, not
        the one associated with the current object. This may be
        desireable in the case where the goal is to restart the
        iterator _after_ the last object previously returned.
        """
        cdef const char *pos_str
        cdef Bs.bstore_iter_pos_t c_pos = self.iterPosGet()
        if c_pos is NULL:
            return None
        pos_str = Bs.bstore_pos_to_str(c_pos)
        free(c_pos)
        if pos_str is NULL:
            return None
        return pos_str

    def set_pos(self, pos):
        cdef int rc
        cdef const char *pos_str = <const char *>pos
        cdef Bs.bstore_iter_pos_t c_pos = Bs.bstore_pos_from_str(pos_str)
        if c_pos is NULL:
            raise ValueError("The input position string is invalid for this iterator.")
        rc = self.iterPosSet(c_pos)
        free(c_pos)
        if rc != 0:
            raise StopIteration("return code: %d" % rc)
        return 0

    cdef Bs.bstore_iter_t iterNew(self):
        raise NotImplementedError

    cdef void iterDel(self):
        raise NotImplementedError

    cdef void *iterObj(self):
        raise NotImplementedError

    cdef void *iterFirst(self):
        raise NotImplementedError

    cdef void *iterNext(self):
        raise NotImplementedError

    cdef void *iterPrev(self):
        raise NotImplementedError

    cdef void *iterLast(self):
        raise NotImplementedError

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        raise NotImplementedError

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t pos):
        raise NotImplementedError


cdef class Btkn_iter(Biter):
    def __init__(self, Bstore store):
        Biter.__init__(self, store)

    cdef Bs.bstore_iter_t iterNew(self):
        return Bs.bstore_tkn_iter_new(self.store.c_store)

    cdef void iterDel(self):
        Bs.bstore_tkn_iter_free(self.c_iter)

    cdef object obj_wrap(self, void *c_obj):
        btkn = Btkn()
        btkn.c_tkn = <Bs.btkn_t>c_obj
        return btkn

    cdef void *iterObj(self):
        return Bs.bstore_tkn_iter_obj(self.c_iter)

    cpdef unsigned long card(self):
        return Bs.bstore_tkn_iter_card(self.c_iter)

    cdef void *iterFirst(self):
        return Bs.bstore_tkn_iter_first(self.c_iter)

    cdef void *iterNext(self):
        return Bs.bstore_tkn_iter_next(self.c_iter)

    cdef void *iterPrev(self):
        return Bs.bstore_tkn_iter_prev(self.c_iter)

    cdef void *iterLast(self):
        return Bs.bstore_tkn_iter_last(self.c_iter)

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        return Bs.bstore_tkn_iter_pos(self.c_iter)

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t c_pos):
        return Bs.bstore_tkn_iter_pos_set(self.c_iter, c_pos)

cdef class Bptn:
    cpdef Bstore store
    cpdef Bs.bptn_t c_ptn
    cdef int c_arg
    def __cinit__(self):
        self.c_ptn = NULL
        self.c_arg = 0

    def __dealloc__(self):
        if self.c_ptn is not NULL:
            Bs.bptn_free(self.c_ptn)
            self.c_ptn = NULL

    cpdef ptn_id(self):
        """Returns the unique Pattern Identifier"""
        return self.c_ptn.ptn_id

    cpdef first_seen(self):
        """Returns the first time this pattern was seen"""
        return self.c_ptn.first_seen.tv_sec

    cpdef last_seen(self):
        """Returns the last time this pattern was seen"""
        return self.c_ptn.last_seen.tv_sec

    cpdef tkn_count(self):
        """Returns the number of token postions in the pattern"""
        return self.c_ptn.tkn_count

    cpdef msg_count(self):
        """Returns the number of messages matching this pattern"""
        return self.c_ptn.count

    cpdef find_tkn(self, size_t pos, Bs.btkn_id_t tkn_id):
        """Search the pattern history at the specified position for a token"""
        cdef Bs.btkn_t c_tkn
        c_tkn = Bs.bstore_ptn_tkn_find(self.store.c_store,
                                       self.c_ptn.ptn_id,
                                       pos,
                                       tkn_id)
        if c_tkn != NULL:
            tkn = Btkn()
            tkn.c_tkn = c_tkn
            return tkn

        return None

    def __iter__(self):
        return self

    def __next__(self):
        cdef Bs.btkn_id_t tkn_id
        if self.c_arg < self.c_ptn.tkn_count:
            tkn_id = self.c_ptn.str.u64str[self.c_arg]
            tkn_id = tkn_id >> 8
            tkn = self.store.tkn_by_id(tkn_id)
            self.c_arg += 1
            return tkn
        self.c_arg = 0
        raise StopIteration

    def __str__(self):
        cdef int arg
        cdef Bs.btkn_id_t tkn_id
        ptn_str = ""
        for arg in range(0, self.c_ptn.tkn_count):
            tkn_id = self.c_ptn.str.u64str[arg]
            tkn_id = tkn_id >> 8
            tkn = self.store.tkn_by_id(tkn_id)
            ptn_str += tkn.ptn_tkn_str()
        return ptn_str

cdef class Bptn_iter(Biter):
    def __init__(self, Bstore store):
        Biter.__init__(self, store)

    @cython.cdivision(True)
    def count(self, start_time, end_time = None):
        """Return the number of messages patterns the condition

        Positional Parameters:
        -- The Unix timestamp for the start of the time period

        Keyword Parameters:
        end_time   -- The Unix timestamp for the end of the time period
        """
        cdef uint32_t start, end
        cdef int rec_count = 0
        cdef Bs.bptn_t ptn
        cdef int more
        start = start_time
        if end_time:
            end = <uint32_t>end_time
        else:
            end = 0

        more = self.find(start_time)
        while more != 0:
            try:
                ptn = Bs.bstore_ptn_iter_next(self.c_iter)
                if ptn == NULL:
                    more = 0
                elif end != 0 and ptn.first_seen.tv_sec > end:
                    more = 0
                else:
                    rec_count += 1
                if ptn != NULL:
                    Bs.bptn_free(ptn)
            except StopIteration:
                more = 0
        return rec_count

    def find(self, start_time):
        return self.obj_update(Bs.bstore_ptn_iter_find(self.c_iter, start_time))

    cdef Bs.bstore_iter_t iterNew(self):
        return Bs.bstore_ptn_iter_new(self.store.c_store)

    cdef void iterDel(self):
        Bs.bstore_ptn_iter_free(self.c_iter)

    cpdef unsigned long card(self):
        return Bs.bstore_ptn_iter_card(self.c_iter)

    cdef object obj_wrap(self, void *c_obj):
        bptn = Bptn()
        bptn.c_ptn = <Bs.bptn_t>c_obj
        bptn.store = self.store
        return bptn

    cdef void *iterObj(self):
        return Bs.bstore_ptn_iter_obj(self.c_iter)

    cdef void *iterFirst(self):
        return Bs.bstore_ptn_iter_first(self.c_iter)

    cdef void *iterNext(self):
        return Bs.bstore_ptn_iter_next(self.c_iter)

    cdef void *iterPrev(self):
        return Bs.bstore_ptn_iter_prev(self.c_iter)

    cdef void *iterLast(self):
        return Bs.bstore_ptn_iter_last(self.c_iter)

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        return Bs.bstore_ptn_iter_pos(self.c_iter)

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t c_pos):
        return Bs.bstore_ptn_iter_pos_set(self.c_iter, c_pos)

cdef class Bptn_tkn_iter(Biter):
    def __init__(self, Bstore store):
        Biter.__init__(self, store)

    def find(self, ptn_id, tkn_pos):
        """Initialize the pattern token iterator position

        Position the pattern-token iterator at the first token of the
        specified position in the pattern. Token positions are
        numbered from 0 to ptn.tkn_count() - 1.

        Positional Parameters:
        -- The pattern id
        -- The token position in the pattern 0.. ptn.tkn_count() - 1
        """
        return self.obj_update(Bs.bstore_ptn_tkn_iter_find(self.c_iter,
                                                  ptn_id, tkn_pos))

    cdef Bs.bstore_iter_t iterNew(self):
        return Bs.bstore_ptn_tkn_iter_new(self.store.c_store)

    cdef void iterDel(self):
        Bs.bstore_ptn_tkn_iter_free(self.c_iter)

    cpdef unsigned long card(self):
        return Bs.bstore_ptn_tkn_iter_card(self.c_iter)

    cdef object obj_wrap(self, void *c_obj):
        btkn = Btkn()
        btkn.c_tkn = <Bs.btkn_t>c_obj
        return btkn

    cdef void *iterObj(self):
        return Bs.bstore_ptn_tkn_iter_obj(self.c_iter)

    cdef void *iterFirst(self):
        return Bs.bstore_ptn_tkn_iter_find(self.c_iter, self.ptn.ptn_id(), 0)

    cdef void *iterNext(self):
        return Bs.bstore_ptn_tkn_iter_next(self.c_iter)

    cdef void *iterPrev(self):
        return Bs.bstore_ptn_tkn_iter_prev(self.c_iter)

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        return Bs.bstore_ptn_tkn_iter_pos(self.c_iter)

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t c_pos):
        return Bs.bstore_ptn_tkn_iter_pos_set(self.c_iter, c_pos)

cdef class Bmsg:
    cpdef Bstore store
    cpdef Bs.bmsg_t c_msg
    cdef int c_arg
    def __cinit__(self):
        self.c_msg = NULL
        self.c_arg = 0

    def __dealloc__(self):
        if self.c_msg is not NULL:
            Bs.bmsg_free(self.c_msg)
            self.c_msg = NULL

    cpdef tv_sec(self):
        if self.c_msg is NULL:
            raise ValueError
        return self.c_msg.timestamp.tv_sec

    cpdef tv_usec(self):
        if self.c_msg is NULL:
            raise ValueError
        return self.c_msg.timestamp.tv_usec

    cpdef ptn_id(self):
        if self.c_msg is NULL:
            raise ValueError
        return self.c_msg.ptn_id

    cpdef comp_id(self):
        if self.c_msg is NULL:
            raise ValueError
        return self.c_msg.comp_id

    cpdef tkn_count(self):
        if self.c_msg is NULL:
            raise ValueError
        return self.c_msg.argc

    def __iter__(self):
        self.c_arg = 0
        return self

    def __next__(self):
        cdef Bs.btkn_id_t tkn_id
        if self.c_arg < self.c_msg.argc:
            tkn_id = self.c_msg.argv[self.c_arg]
            tkn_id = tkn_id >> 8
            tkn = self.store.tkn_by_id(tkn_id)
            self.c_arg += 1
            return tkn
        raise StopIteration

cdef class Bmsg_iter(Biter):
    def __init__(self, Bstore store):
        Biter.__init__(self, store)

    cdef Bs.bstore_iter_t iterNew(self):
        return Bs.bstore_msg_iter_new(self.store.c_store)

    cdef void iterDel(self):
        Bs.bstore_msg_iter_free(self.c_iter)

    cpdef unsigned long card(self):
        return Bs.bstore_msg_iter_card(self.c_iter)

    cdef object obj_wrap(self, void *c_obj):
        bmsg = Bmsg()
        bmsg.c_msg = <Bs.bmsg_t>c_obj
        bmsg.store = self.store
        return bmsg

    cdef void *iterObj(self):
        return Bs.bstore_msg_iter_obj(self.c_iter)

    cdef void *iterFirst(self):
        return Bs.bstore_msg_iter_first(self.c_iter)

    cdef void *iterLast(self):
        return Bs.bstore_msg_iter_last(self.c_iter)

    cdef void *iterNext(self):
        return Bs.bstore_msg_iter_next(self.c_iter)

    cdef void *iterPrev(self):
        return Bs.bstore_msg_iter_prev(self.c_iter)

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        return Bs.bstore_msg_iter_pos(self.c_iter)

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t c_pos):
        return Bs.bstore_msg_iter_pos_set(self.c_iter, c_pos)

    cpdef start(self, Bs.bcomp_id_t comp_id, Bs.bptn_id_t ptn_id, Bs.time_t start):
        """Postion the iterator at a matching message

        Search the index for a message that matches the specified
        start condition and position the iterator at or before this
        message.

        Positional Parameters:
        -- The component id on which the message was reported
        -- The pattern id that this message matches
        -- The start time in seconds since the Epoch
        """
        return self.obj_update(Bs.bstore_msg_iter_find(self.c_iter,
                                                       start, ptn_id, comp_id,
                                                       NULL, NULL))
        return self.py_obj

    @cython.cdivision(True)
    def count(self, ptn_id, start_time = None, end_time = None):
        """Return the number of messages matching a condition

        Positional Parameters:
        -- The id for the pattern this message matches

        Keyword Parameters:
        start_time -- The Unix timestamp of the first message
        end_time   -- The Unix timestamp of the last message
        """
        cdef uint32_t start, end, delta, bin_width
        cdef Bs.bptn_hist_iter_t it
        cdef Bs.bptn_hist_s hist
        cdef Bs.bptn_hist_t ph
        cdef size_t msg_count
        cdef Bmsg m

        if not start_time:
            m = self.first()
            if not m:
                return 0
            start = m.tv_sec()
        else:
            start = start_time

        if not end_time:
            m = self.last()
            end = m.tv_sec()
        else:
            end = end_time

        delta = end - start
        if delta > 3600:
            bin_width = 3600
        else:
            bin_width = 60
        start = start - (start % bin_width)
        end += bin_width - 1
        end = end - (end % bin_width)

        hist.ptn_id = ptn_id
        hist.bin_width = bin_width
        hist.time = start

        msg_count = 0
        it = Bs.bstore_ptn_hist_iter_new(self.store.c_store)
        ph = &hist
        ph = Bs.bstore_ptn_hist_iter_first(it, ph)
        while ph != NULL:
            if ph.time > end:
                break
            msg_count = msg_count + ph.msg_count
            ph = Bs.bstore_ptn_hist_iter_next(it, ph)
        Bs.bstore_ptn_hist_iter_free(it)

        return msg_count

cdef class Bptn_hist:
    cdef Bs.bptn_hist_s c_hist

    cpdef ptn_id(self):
        return self.c_hist.ptn_id

    cpdef bin_width(self):
        return self.c_hist.bin_width

    cpdef time(self):
        return self.c_hist.time

    cpdef msg_count(self):
        return self.c_hist.msg_count

cdef int __bin_width__(s):
    bw = s.upper()
    if bw == 'D':
        return 86400
    elif bw == 'H':
        return 3600
    elif bw == 'M':
        return 60
    raise ValueError("A bin-width specification must be one of: " \
                     "d, h, or m for Days, Hours, Minutes")


cdef class Bptn_hist_iter(Biter):
    """Pattern History Iterator"""
    cdef Bs.bptn_hist_s c_ptn_h

    def __init__(self, Bstore store):
        Biter.__init__(self, store)

    def start(self, ptn_id, bin_width, time):
        self.c_ptn_h.ptn_id = ptn_id
        self.c_ptn_h.bin_width = bin_width
        self.c_ptn_h.time = time
        self.c_ptn_h.msg_count = 0
        return self.obj_update(Bs.bstore_ptn_hist_iter_first(
                                                self.c_iter, &self.c_ptn_h))

    def end(self, ptn_id, bin_width, time):
        self.c_ptn_h.ptn_id = ptn_id
        self.c_ptn_h.bin_width = bin_width
        self.c_ptn_h.time = time
        self.c_ptn_h.msg_count = 0
        return self.obj_update(Bs.bstore_ptn_hist_iter_last(
                                                self.c_iter, &self.c_ptn_h))

    cdef Bs.bstore_iter_t iterNew(self):
        return Bs.bstore_ptn_hist_iter_new(self.store.c_store)

    cdef void iterDel(self):
        Bs.bstore_ptn_hist_iter_free(self.c_iter)

    cdef object obj_wrap(self, void *c_obj):
        ptn_h = Bptn_hist()
        ptn_h.c_hist = (<Bs.bptn_hist_t>c_obj)[0]
        return ptn_h

    cdef void *iterObj(self):
        return Bs.bstore_ptn_hist_iter_obj(self.c_iter, &self.c_ptn_h)

    cdef void *iterFirst(self):
        return Bs.bstore_ptn_hist_iter_first(self.c_iter, &self.c_ptn_h)

    cdef void *iterNext(self):
        return Bs.bstore_ptn_hist_iter_next(self.c_iter, &self.c_ptn_h)

    cdef void *iterLast(self):
        return Bs.bstore_ptn_hist_iter_last(self.c_iter, &self.c_ptn_h)

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        return Bs.bstore_ptn_hist_iter_pos(self.c_iter)

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t c_pos):
        return Bs.bstore_ptn_hist_iter_pos_set(self.c_iter, c_pos)

    def duration(self, ptn_id, start=None):
        cdef Bs.bptn_hist_t h
        self.c_ptn_h.ptn_id = ptn_id
        self.c_ptn_h.bin_width = 60
        self.c_ptn_h.time = 0
        self.c_ptn_h.msg_count = 0

        if start:
            self.c_ptn_h.time = start

        h = Bs.bstore_ptn_hist_iter_first(self.c_iter, &self.c_ptn_h)
        if h == NULL:
            return 0
        start = h.time

        self.c_ptn_h.time = 0xffffffff;
        h = Bs.bstore_ptn_hist_iter_last(self.c_iter, &self.c_ptn_h)
        end = h.time

        return end - start

    def count(self, ptn_id, bin_width, start_time=None, end_time=None):
        cdef uint32_t end
        cdef void *c_obj;
        self.c_ptn_h.ptn_id = ptn_id
        self.c_ptn_h.bin_width = bin_width
        self.c_ptn_h.msg_count = 0
        self.c_ptn_h.time
        if start_time:
            self.c_ptn_h.time = start_time
        else:
            self.c_ptn_h.time = 0
        if end_time:
            end = end_time
        else:
            end = 0
        c_obj = Bs.bstore_ptn_hist_iter_first(self.c_iter, &self.c_ptn_h)
        rec_count = 0
        while c_obj != NULL:
            if end > 0 and self.c_ptn_h.time > end:
                break
            rec_count += 1
            c_obj = Bs.bstore_ptn_hist_iter_next(self.c_iter, &self.c_ptn_h)

        return rec_count

    def as_xy_arrays(self, ptn_id, bin_width, start_time=None, end_time=None):
        cdef uint32_t end
        cdef void *c_obj
        cdef int rec_no
        self.c_ptn_h.ptn_id = ptn_id
        self.c_ptn_h.msg_count = 0
        if start_time:
            self.c_ptn_h.time = start_time
        else:
            self.c_ptn_h.time = 0
        if end_time:
            end = end_time
        else:
            end = 0
        self.c_ptn_h.bin_width = bin_width
        c_obj = Bs.bstore_ptn_hist_iter_first(self.c_iter, &self.c_ptn_h)

        x = Array.Array()
        y = Array.Array()

        # shape = []
        # shape.append(<np.npy_intp>sample_count)
        # x = np.zeros(shape, dtype=np.float64, order='C')
        # y = np.zeros(shape, dtype=np.float64, order='C')
        rec_no = 0
        while c_obj != NULL:
            if end > 0 and end < self.c_ptn_h.time:
                break
            x.append(self.c_ptn_h.time)
            y.append(self.c_ptn_h.msg_count)
            rec_no += 1
            c_obj = Bs.bstore_ptn_hist_iter_next(self.c_iter, &self.c_ptn_h)

        return (rec_no, x.as_ndarray(), y.as_ndarray())

cdef class Bcomp_hist:
    cpdef Bs.bcomp_hist_s c_hist

    def comp_id(self):
        return self.c_hist.comp_id

    def ptn_id(self):
        return self.c_hist.ptn_id

    def bin_width(self):
        return self.c_hist.bin_width

    def time(self):
        return self.c_hist.time

    def msg_count(self):
        return self.c_hist.msg_count

cdef class Bcomp_hist_iter(Biter):
    """Component History Iterator"""
    cdef Bs.bcomp_hist_s c_comp_h

    def __init__(self, Bstore store):
        Biter.__init__(self, store)

    def start(self, comp_id, ptn_id, bin_width, time):
        self.c_comp_h.comp_id = comp_id
        self.c_comp_h.ptn_id = ptn_id
        self.c_comp_h.bin_width = bin_width
        self.c_comp_h.time = time
        self.c_comp_h.msg_count = 0
        return self.obj_update(Bs.bstore_comp_hist_iter_first(self.c_iter,
                                        &self.c_comp_h))

    def end(self, comp_id, ptn_id, bin_width, time):
        self.c_comp_h.comp_id = comp_id
        self.c_comp_h.ptn_id = ptn_id
        self.c_comp_h.bin_width = bin_width
        self.c_comp_h.time = time
        self.c_comp_h.msg_count = 0
        return self.obj_update(Bs.bstore_comp_hist_iter_last(self.c_iter,
                                        &self.c_comp_h))
        return self.py_obj

    cdef Bs.bstore_iter_t iterNew(self):
        return Bs.bstore_comp_hist_iter_new(self.store.c_store)

    cdef void iterDel(self):
        Bs.bstore_comp_hist_iter_free(self.c_iter)

    cdef object obj_wrap(self, void *c_obj):
        comp_h = Bcomp_hist()
        comp_h.c_hist = (<Bs.bcomp_hist_t>c_obj)[0]
        return comp_h

    cdef void *iterObj(self):
        return Bs.bstore_comp_hist_iter_obj(self.c_iter, &self.c_comp_h)

    cdef void *iterFirst(self):
        return Bs.bstore_comp_hist_iter_first(self.c_iter, &self.c_comp_h)

    cdef void *iterNext(self):
        return Bs.bstore_comp_hist_iter_next(self.c_iter, &self.c_comp_h)

    cdef void *iterLast(self):
        return Bs.bstore_comp_hist_iter_last(self.c_iter, &self.c_comp_h)

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        return Bs.bstore_comp_hist_iter_pos(self.c_iter)

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t c_pos):
        return Bs.bstore_comp_hist_iter_pos_set(self.c_iter, c_pos)

    def duration(self, comp_id, start=None):
        cdef Bs.bcomp_hist_t h
        self.c_comp_h.comp_id = comp_id
        self.c_comp_h.bin_width = 60
        self.c_comp_h.time = 0
        self.c_comp_h.msg_count = 0

        if start:
            self.c_comp_h.time = start

        h = Bs.bstore_comp_hist_iter_first(self.c_iter, &self.c_comp_h)
        if h == NULL:
            return 0
        start = h.time

        self.c_comp_h.time = 0xffffffff;
        h = Bs.bstore_comp_hist_iter_last(self.c_iter, &self.c_comp_h)
        end = h.time

        return end - start

    def count(self, comp_id, bin_width, ptn_id=None, start_time=None, end_time=None):
        cdef uint32_t end
        cdef void *c_obj
        self.c_comp_h.comp_id = comp_id
        self.c_comp_h.bin_width = bin_width
        self.c_comp_h.msg_count = 0
        self.c_comp_h.time
        if start_time:
            self.c_comp_h.time = start_time
        else:
            self.c_comp_h.time = 0
        if end_time:
            end = end_time
        else:
            end = 0
        if ptn_id:
            self.c_comp_h.ptn_id = <Bs.bptn_id_t>ptn_id

        c_obj = Bs.bstore_comp_hist_iter_first(self.c_iter, &self.c_comp_h)
        rec_count = 0
        while c_obj != NULL:
            if end > 0 and self.c_comp_h.time > end:
                break
            rec_count += 1
            c_obj = Bs.bstore_comp_hist_iter_next(self.c_iter, &self.c_comp_h)

        return rec_count

    def as_xy_arrays(self, comp_id, ptn_id, bin_width, start_time=None, end_time=None):
        cdef uint32_t end
        cdef int rec_no
        cdef void *c_obj

        self.c_comp_h.comp_id = comp_id
        self.c_comp_h.ptn_id = ptn_id
        self.c_comp_h.bin_width = bin_width
        self.c_comp_h.msg_count = 0

        if start_time:
            self.c_comp_h.time = start_time
        else:
            self.c_comp_h.time = 0

        if end_time:
            end = end_time
        else:
            end = 0

        c_obj = Bs.bstore_comp_hist_iter_first(self.c_iter, &self.c_comp_h)

        x = Array.Array()
        y = Array.Array()

        rec_no = 0
        while c_obj != NULL:
            if end > 0 and end < self.c_comp_h.time:
                break
            x.append(self.c_comp_h.time)
            y.append(self.c_comp_h.msg_count)
            rec_no += 1
            c_obj = Bs.bstore_comp_hist_iter_next(self.c_iter, &self.c_comp_h)

        return (rec_no, x.as_ndarray(), y.as_ndarray())

cdef class Btkn_hist:
    cpdef Bs.btkn_hist_s c_hist

    def tkn_id(self):
        return self.c_hist.tkn_id

    def bin_width(self):
        return self.c_hist.bin_width

    def time(self):
        return self.c_hist.time

    def tkn_count(self):
        return self.c_hist.tkn_count

cdef class Btkn_hist_iter(Biter):
    """Btkn History Iterator"""
    cdef Bs.btkn_hist_s c_tkn_h

    def __init__(self, Bstore store):
        Biter.__init__(self, store)

    def start(self, tkn_id, bin_width, time):
        """Set the iterator at the entry matching the start condition

        Set the iterator at the position of the token history entry
        that matches the specified start condition.

        Positional Parameters:
        -- The token id
        -- The bin width
        -- The start time as a Unix timestamp
        """
        self.c_tkn_h.tkn_id = tkn_id
        self.c_tkn_h.bin_width = bin_width
        self.c_tkn_h.time = time
        self.c_tkn_h.tkn_count = 0
        return self.obj_update(Bs.bstore_tkn_hist_iter_first(self.c_iter,
                                                            &self.c_tkn_h))

    def end(self, tkn_id, bin_width, time):
        self.c_tkn_h.tkn_id = tkn_id
        self.c_tkn_h.bin_width = bin_width
        self.c_tkn_h.time = time
        self.c_tkn_h.tkn_count = 0
        return self.obj_update(Bs.bstore_tkn_hist_iter_last(self.c_iter,
                                                            &self.c_tkn_h))

    cdef Bs.bstore_iter_t iterNew(self):
        return Bs.bstore_tkn_hist_iter_new(self.store.c_store)

    cdef void iterDel(self):
        Bs.bstore_tkn_hist_iter_free(self.c_iter)

    cdef object obj_wrap(self, void *c_obj):
        tkn_h = Btkn_hist()
        tkn_h.c_hist = (<Bs.btkn_hist_t>c_obj)[0]
        return tkn_h

    cdef void *iterObj(self):
        return Bs.bstore_tkn_hist_iter_obj(self.c_iter, &self.c_tkn_h)

    cdef void *iterFirst(self):
        return Bs.bstore_tkn_hist_iter_first(self.c_iter, &self.c_tkn_h)

    cdef void *iterNext(self):
        return Bs.bstore_tkn_hist_iter_next(self.c_iter, &self.c_tkn_h)

    cdef void *iterLast(self):
        return Bs.bstore_tkn_hist_iter_last(self.c_iter, &self.c_tkn_h)

    cdef Bs.bstore_iter_pos_t iterPosGet(self):
        return Bs.bstore_tkn_hist_iter_pos(self.c_iter)

    cdef int iterPosSet(self, Bs.bstore_iter_pos_t c_pos):
        return Bs.bstore_tkn_hist_iter_pos_set(self.c_iter, c_pos)

    def duration(self, tkn_id, start=None):
        """Return the duration in seconds of the token history

        Positional Parameters:
        -- The token id

        Keyword Parameters:
        start -- The Unix timestamp of the first history entry
        """
        cdef Bs.btkn_hist_t h
        self.c_tkn_h.tkn_id = tkn_id
        self.c_tkn_h.bin_width = 60
        self.c_tkn_h.time = 0
        self.c_tkn_h.tkn_count = 0

        if start:
            self.c_tkn_h.time = start

        h = Bs.bstore_tkn_hist_iter_first(self.c_iter, &self.c_tkn_h)
        if h == NULL:
            return 0
        start = h.time

        self.c_tkn_h.time = 0xffffffff;
        h = Bs.bstore_tkn_hist_iter_last(self.c_iter, &self.c_tkn_h)
        end = h.time

        return end - start

    def count(self, tkn_id, bin_width, ptn_id=None, start_time=None, end_time=None):
        cdef uint32_t end
        cdef void *c_obj
        self.c_tkn_h.tkn_id = tkn_id
        self.c_tkn_h.bin_width = bin_width
        self.c_tkn_h.msg_count = 0
        self.c_tkn_h.time
        if start_time:
            self.c_tkn_h.time = start_time
        else:
            self.c_tkn_h.time = 0
        if end_time:
            end = end_time
        else:
            end = 0
        if ptn_id:
            self.c_tkn_h.ptn_id = <Bs.bptn_id_t>ptn_id

        c_obj = Bs.bstore_tkn_hist_iter_first(self.c_iter, &self.c_tkn_h)
        rec_count = 0
        while c_obj != NULL:
            if end > 0 and self.c_tkn_h.time > end:
                break
            rec_count += 1
            c_obj = Bs.bstore_tkn_hist_iter_next(self.c_iter, &self.c_tkn_h)

        return rec_count

    def as_xy_arrays(self, tkn_id, bin_width, start_time=None, end_time=None):
        cdef uint32_t end
        cdef int rec_no
        cdef void *c_obj

        self.c_tkn_h.tkn_id = tkn_id
        self.c_tkn_h.tkn_count = 0
        if start_time:
            self.c_tkn_h.time = start_time
        else:
            self.c_tkn_h.time = 0
        if end_time:
            end = end_time
        else:
            end = 0
        self.c_tkn_h.bin_width = bin_width
        c_obj = Bs.bstore_tkn_hist_iter_first(self.c_iter, &self.c_tkn_h)

        x = Array.Array()
        y = Array.Array()

        rec_no = 0
        while c_obj != NULL:
            if end > 0 and end < self.c_tkn_h.time:
                break
            x.append(self.c_tkn_h.time)
            y.append(self.c_tkn_h.tkn_count)
            rec_no += 1
            c_obj = Bs.bstore_tkn_hist_iter_next(self.c_iter, &self.c_tkn_h)

        return (rec_no, x.as_ndarray(), y.as_ndarray())