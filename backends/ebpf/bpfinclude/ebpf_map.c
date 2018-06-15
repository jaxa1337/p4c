/*
Copyright 2018 VMware, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/*
Implementation of userlevel eBPF map structure. Emulates the linux kernel bpf maps.
*/

#include <assert.h>

#include "ebpf_map.h"

enum bpf_flags {
    BPF_ANY,  // create new element or update existing
    BPF_NOEXIST,  // create new element only if it didn't exist
    BPF_EXIST  // only update existing element
};

static int check_flags(void *elem, unsigned long long map_flags) {
    if (map_flags > BPF_EXIST)
        /* unknown flags */
        return EXIT_FAILURE;
    if (elem && map_flags == BPF_NOEXIST)
        /* elem already exists */
        return EXIT_FAILURE;

    if (!elem && map_flags == BPF_EXIST)
        /* elem doesn't exist, cannot update it */
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}

void *bpf_map_lookup_elem(struct bpf_map *map, void *key, unsigned int key_size) {
    struct bpf_map *tmp_map;
    HASH_FIND(hh, map, key, key_size, tmp_map);
    if (tmp_map == NULL)
        return NULL;
    return tmp_map->value;
}


int bpf_map_update_elem(struct bpf_map *map, void *key, unsigned int key_size, void *value,
                  unsigned long long flags) {
    struct bpf_map *tmp_map;
    HASH_FIND(hh, map, key, key_size, tmp_map);
    int ret = check_flags(tmp_map, flags);
    if (ret)
        return ret;
    if (!tmp_map) {
        tmp_map = (struct bpf_map *) malloc(sizeof(struct bpf_map));
        tmp_map->key = key;
        HASH_ADD_KEYPTR(hh, map, key, key_size, tmp_map);
    }
    tmp_map->value = value;
    return EXIT_SUCCESS;
}

int bpf_map_delete_elem(struct bpf_map *map, void *key, unsigned int key_size) {
    struct bpf_map *tmp_map;
    HASH_FIND(hh, map, key, key_size, tmp_map);
    if (tmp_map != NULL) {
        HASH_DEL(map, tmp_map);
        free(tmp_map);
    }
    return EXIT_SUCCESS;
}
