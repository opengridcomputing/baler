/* -*- c-basic-offset: 8 -*-
 * Copyright (c) 2015 Open Grid Computing, Inc. All rights reserved.
 * Copyright (c) 2015 Sandia Corporation. All rights reserved.
 *
 * Under the terms of Contract DE-AC04-94AL85000, there is a non-exclusive
 * license for use of this work by or on behalf of the U.S. Government.
 * Export of this program may require a license from the United States
 * Government.
 *
 * This software is available to you under a choice of one of two
 * licenses.  You may choose to be licensed under the terms of the GNU
 * General Public License (GPL) Version 2, available from the file
 * COPYING in the main directory of this source tree, or the BSD-type
 * license below:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *      Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *      Redistributions in binary form must reproduce the above
 *      copyright notice, this list of conditions and the following
 *      disclaimer in the documentation and/or other materials provided
 *      with the distribution.
 *
 *      Neither the name of Sandia nor the names of any contributors may
 *      be used to endorse or promote products derived from this software
 *      without specific prior written permission.
 *
 *      Neither the name of Open Grid Computing nor the names of any
 *      contributors may be used to endorse or promote products derived
 *      from this software without specific prior written permission.
 *
 *      Modified source versions must be plainly marked as such, and
 *      must not be misrepresented as being the original software.
 *
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * \file bheap.c
 * \author Narate Taerat (narate at ogc dot us)
 */
#include "bheap.h"
#include "butils.h"

struct bheap *bheap_new(int alloc_len, int (*cmp)(void*,void*))
{
	struct bheap *h = NULL;
	h = calloc(1, sizeof(*h));
	if (!h)
		goto out;
	h->cmp = cmp;
	h->alloc_len = alloc_len;
	h->array = malloc(alloc_len * sizeof(*h->array));
	if (!h)
		goto err0;
	goto out;
err0:
	free(h);
	h = NULL;
out:
	return h;
}

void bheap_free(struct bheap *h)
{
	free(h->array);
	free(h);
}

int bheap_insert(struct bheap *h, void *elm)
{
	int i, p, cmp;
	if (h->len == h->alloc_len) {
		/* try expanding ... */
		int new_len = h->alloc_len + 4096;
		void **tmp = realloc(h->array, new_len * sizeof(*h->array));
		if (!tmp)
			return ENOMEM;
		h->alloc_len = new_len;
		h->array = tmp;
	}
	i = h->len;
	h->len++;
	while (i) {
		p = (i-1)/2;
		cmp = h->cmp(elm, h->array[p]);
		if (cmp >= 0) {
			break;
		}
		h->array[i] = h->array[p];
		i = p;
	}
	h->array[i] = elm;
	return 0;
}

void* bheap_remove_top(struct bheap *h)
{
	void *tmp = bheap_get_top(h);
	if (!tmp)
		return NULL;
	h->len--;
	h->array[0] = h->array[h->len];
	bheap_percolate_top(h);
	return tmp;
}

void* bheap_get_top(struct bheap *h)
{
	if (h->len)
		return h->array[0];
	return NULL;
}

void bheap_percolate_top(struct bheap *h)
{
	int i, l, r, d;
	int cmp;
	void *tmp = h->array[0];
	i = 0;
	l = 1;
	r = 2;
	while (r < h->len) {
		cmp = h->cmp(h->array[l], h->array[r]);
		if (cmp < 0) {
			cmp = h->cmp(tmp, h->array[l]);
			d = l;
		} else {
			cmp = h->cmp(tmp, h->array[r]);
			d = r;
		}

		if (cmp <= 0)
			break;

		h->array[i] = h->array[d];

		i = d;
		l = i*2+1;
		r = l+1;
	}

	if (l < h->len) {
		cmp = h->cmp(tmp, h->array[l]);
		if (cmp > 0) {
			h->array[i] = h->array[l];
			i = l;
		}
	}

	h->array[i] = tmp;
}

int bheap_verify(struct bheap *h)
{
	int i, l, r;
	for (i = 0; i < h->len; i++) {
		l = i*2+1;
		r = l+1;
		if (l < h->len) {
			if (h->cmp(h->array[i], h->array[l]) > 0)
				return EINVAL;
		}
		if (r < h->len) {
			if (h->cmp(h->array[i], h->array[r]) > 0)
				return EINVAL;
		}
	}
	return 0;
}

void bheap_heapify(struct bheap *h)
{
	int i;
	int len = h->len;
	/* reset && reinsert */
	h->len = 0;
	for (i = 0; i < len; i++) {
		bheap_insert(h, h->array[i]);
	}
}

void bheap_set_cmp(struct bheap *h, int (*cmp)(void*,void*))
{
	h->cmp = cmp;
	bheap_heapify(h);
}
